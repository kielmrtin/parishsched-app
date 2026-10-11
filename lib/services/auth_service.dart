import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';
import '../security/secure_session_storage.dart';

/// Thrown for any auth/registration failure, carrying a message that's
/// already safe to show to the user.
class AuthFailure implements Exception {
  final String message;
  AuthFailure(this.message);

  @override
  String toString() => message;
}

/// Mirrors church-web's Auth/CustomerAuthController: Supabase Auth for
/// credentials, a `customers` row (linked by `auth_id`) for the profile,
/// and a `status` check that blocks disabled accounts.
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final authId = response.user?.id;
      if (authId == null) {
        throw AuthFailure('Unable to read your account. Please try again.');
      }

      final customer = await _fetchCustomerByAuthId(authId);
      if (customer == null) {
        await _client.auth.signOut();
        throw AuthFailure(
          'Account profile not found. Please contact the parish office or register again.',
        );
      }
      if ((customer['status'] ?? 'active') == 'disabled') {
        await _client.auth.signOut();
        throw AuthFailure(
          'Your account has been disabled by the administrator.',
        );
      }
      return customer;
    } on AuthException catch (e) {
      throw AuthFailure(_friendlyAuthMessage(e));
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'address': address,
          // Privacy Policy consent (required by the register screen).
          'privacy_consent_at': DateTime.now().toUtc().toIso8601String(),
          'privacy_policy_version': 'October 2026',
        },
      );
      final authId = response.user?.id;
      if (authId == null) {
        throw AuthFailure('Account was created but no auth ID was returned.');
      }

      await _client.from('customers').insert({
        'auth_id': authId,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'role': 'customer',
      });
    } on AuthException catch (e) {
      throw AuthFailure(_friendlyAuthMessage(e));
    } on PostgrestException catch (e) {
      throw AuthFailure(
        'Your account was created, but saving your profile failed: ${e.message}',
      );
    }
  }

  /// Re-checks the logged-in user's `customers.status`, matching
  /// CheckCustomerStatus middleware's behavior on every protected page load.
  Future<Map<String, dynamic>?> refreshProfileOrSignOut() async {
    final authId = currentUser?.id;
    if (authId == null) return null;

    final customer = await _fetchCustomerByAuthId(authId);
    if (customer == null || (customer['status'] ?? 'active') == 'disabled') {
      await _client.auth.signOut();
      return null;
    }
    return customer;
  }

  /// Calls church-web's `/api/mobile-send-otp` (CustomerAuthController::
  /// sendRegisterOtp), which generates the code, stores it in
  /// `customer_otps` with the service-role key, and sends it by real SMS.
  /// The app never touches `customer_otps` directly — that table only
  /// accepts the Laravel service-role key, not the anon key.
  Future<void> sendRegisterOtp(String phone) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/mobile-send-otp'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 15));

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (!ok) {
      final message = _messageFromJson(response.body) ??
          'Could not send the verification code. Please try again.';
      throw AuthFailure(message);
    }
  }

  /// Calls church-web's `/api/mobile-verify-otp` — checks the code against
  /// `customer_otps` server-side and marks it used. Must return true before
  /// the app proceeds with its own Supabase Auth signUp below.
  Future<bool> verifyRegisterOtp(String phone, String otpCode) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/mobile-verify-otp'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'phone': phone, 'otp_code': otpCode}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) return true;
    if (response.statusCode == 422) return false;
    throw AuthFailure(
      _messageFromJson(response.body) ??
          'Could not verify the code. Please try again.',
    );
  }

  String? _messageFromJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {}
    return null;
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Permanently deletes the signed-in account and its data through
  /// church-web's /api/mobile-delete-account (only the server holds the
  /// service-role key needed to remove a login). The request is
  /// authenticated with the user's own access token. Then wipes this
  /// phone's local app data.
  Future<void> deleteAccount() async {
    final token = currentSession?.accessToken;
    if (token == null) throw AuthFailure('Please sign in again.');
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/mobile-delete-account'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw AuthFailure('Could not reach the parish server. Please check your connection.');
    }
    if (response.statusCode != 200) {
      throw AuthFailure(
        _messageFromJson(response.body) ??
            'We could not delete your account. Please try again later.',
      );
    }
    try {
      await _client.auth.signOut();
    } catch (_) {
      // The login was already deleted server-side; just drop it locally.
    }
    await wipeLocalAppData();
  }

  /// Everything the parish holds about the signed-in user in ParishSched:
  /// their profile and their reservations (with uploaded document links).
  Future<Map<String, dynamic>> fetchMyData() async {
    final customer = await fetchCurrentCustomer();
    final email = currentUser?.email;
    final filters = [
      if (customer?['id'] != null) 'customer_id.eq.${customer!['id']}',
      if (email != null) 'email.eq."$email"',
    ];
    List<dynamic> reservations = [];
    if (filters.isNotEmpty) {
      Future<List<dynamic>> query(String columns) => _client
          .from('reservations')
          .select(columns)
          .or(filters.join(','))
          .order('reservation_date', ascending: false);
      try {
        reservations = await query('*, reservation_attachments(label, file_url)');
      } on PostgrestException {
        // Attachments not readable/related for this user: reservations only.
        reservations = await query('*');
      }
    }
    return {
      'profile': customer,
      'reservations': reservations,
    };
  }

  /// church-web's own forgot-password flow calls Supabase Auth's admin API
  /// with the service-role key, which must never ship in this app. Supabase
  /// Auth's own `resetPasswordForEmail` achieves the same outcome (a reset
  /// email sent by Supabase) using only the anon key. `redirectTo` points at
  /// the custom scheme registered in AndroidManifest.xml, which
  /// supabase_flutter listens for and turns into a `passwordRecovery` auth
  /// event once the app catches it.
  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'parishsched://reset-callback',
    );
  }

  /// Called from the reset-password screen once the app is holding a
  /// recovery session (after tapping the emailed link).
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw AuthFailure(_friendlyAuthMessage(e));
    }
  }

  /// Fetches the signed-in user's `customers` row — the source of truth
  /// for their name, used as a fallback when Auth metadata has none
  /// (e.g. accounts created before `full_name` was stored at sign-up).
  Future<Map<String, dynamic>?> fetchCurrentCustomer() async {
    final authId = currentUser?.id;
    if (authId == null) return null;
    return _fetchCustomerByAuthId(authId);
  }

  Future<Map<String, dynamic>?> _fetchCustomerByAuthId(String authId) async {
    final rows = await _client
        .from('customers')
        .select()
        .eq('auth_id', authId)
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  String _friendlyAuthMessage(AuthException e) {
    final code = e.code ?? '';
    if (code.contains('email_not_confirmed')) {
      return 'Your email is not yet verified. Please check your inbox and click the confirmation link that was sent when you registered.';
    }
    if (code.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (code.contains('user_not_found')) {
      return 'No account found with that email address.';
    }
    if (code.contains('user_already_exists') || code.contains('email_exists')) {
      return 'An account with that email already exists. Try signing in instead.';
    }
    return e.message.isNotEmpty
        ? e.message
        : 'Something went wrong. Please try again.';
  }
}
