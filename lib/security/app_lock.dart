import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

/// Local authentication with the phone's own screen lock (fingerprint,
/// face, PIN, pattern or password) - MASVS-AUTH:
///  * unlocking the app when a saved login is reopened ([AppLockGate]);
///  * confirming sensitive actions (submitting / cancelling a reservation,
///    deleting the account) via [AppLock.confirm].
class AppLock {
  AppLock._();

  static final _auth = LocalAuthentication();

  /// True once the user has unlocked during this app session.
  static bool unlocked = false;

  /// Asks for the phone's screen lock. Returns true when verified, and also
  /// when the phone has no screen lock set at all (nothing to verify with).
  static Future<bool> confirm(String reason) async {
    try {
      if (!await _auth.isDeviceSupported()) return true;
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      return e.code == LocalAuthExceptionCode.noCredentialsSet;
    } catch (_) {
      return false;
    }
  }
}

/// Sits above every screen (MaterialApp.builder). While someone is signed
/// in and hasn't unlocked yet - i.e. a saved login was reopened, or the app
/// sat in the background for [_relockAfter] - the app is covered by a lock
/// screen until the phone's screen lock is passed. Signing in with a
/// password counts as unlocking.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child, required this.onSignedOut});

  final Widget child;

  /// Called after "Sign out instead", to send the app back to Welcome.
  final VoidCallback onSignedOut;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  static const _relockAfter = Duration(minutes: 5);
  final _client = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSub;
  DateTime? _backgroundedAt;
  bool _busy = false;

  bool get _locked => _client.auth.currentSession != null && !AppLock.unlocked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSub = _client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.signedIn) AppLock.unlocked = true;
      if (data.event == AuthChangeEvent.signedOut) AppLock.unlocked = false;
      setState(() {});
    });
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _backgroundedAt != null) {
      final away = DateTime.now().difference(_backgroundedAt!);
      _backgroundedAt = null;
      if (AppLock.unlocked && away >= _relockAfter && _client.auth.currentSession != null) {
        setState(() => AppLock.unlocked = false);
        _unlock();
      }
    }
  }

  Future<void> _unlock() async {
    if (_busy || !_locked) return;
    setState(() => _busy = true);
    final ok = await AppLock.confirm('Unlock ParishSched');
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) AppLock.unlocked = true;
    });
  }

  Future<void> _signOut() async {
    await _client.auth.signOut();
    widget.onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    // The app stays mounted underneath (keeps navigation state); the lock
    // screen just covers it.
    return Stack(
      children: [
        widget.child,
        if (_locked) Positioned.fill(child: _lockScreen()),
      ],
    );
  }

  Widget _lockScreen() {
    return Scaffold(
      backgroundColor: AppColors.brand,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 60, color: Colors.white),
                const SizedBox(height: 18),
                const Text(
                  'ParishSched is locked',
                  style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use your fingerprint or phone PIN to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 26),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _unlock,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('UNLOCK'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.brand,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _signOut,
                  child: const Text('Sign out instead', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
