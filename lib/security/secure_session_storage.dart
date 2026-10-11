import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Encrypted on-device storage (AES-GCM with a key held in the Android
/// Keystore). Used for the login session and the password-reset PKCE code
/// instead of supabase_flutter's default plain-text SharedPreferences
/// (MASVS-STORAGE / MASVS-CRYPTO).
const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(storageNamespace: 'parishsched_secure'),
);

/// Supabase session persistence backed by [_secureStorage].
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage();

  static const _key = supabasePersistSessionKey;

  @override
  Future<void> initialize() async {
    // One-time move of a session saved by older app versions out of plain
    // SharedPreferences, so updating doesn't log anyone out and no
    // plain-text token is left behind.
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_key);
    if (legacy != null) {
      if (!await _secureStorage.containsKey(key: _key)) {
        await _secureStorage.write(key: _key, value: legacy);
      }
      await prefs.remove(_key);
    }
  }

  @override
  Future<bool> hasAccessToken() => _secureStorage.containsKey(key: _key);

  @override
  Future<String?> accessToken() => _secureStorage.read(key: _key);

  @override
  Future<void> removePersistedSession() => _secureStorage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _secureStorage.write(key: _key, value: persistSessionString);
}

/// Storage for the short-lived PKCE code verifier used by the password-reset
/// deep link, also kept encrypted.
class SecurePkceStorage extends GotrueAsyncStorage {
  const SecurePkceStorage();

  @override
  Future<String?> getItem({required String key}) => _secureStorage.read(key: key);

  @override
  Future<void> setItem({required String key, required String value}) =>
      _secureStorage.write(key: key, value: value);

  @override
  Future<void> removeItem({required String key}) => _secureStorage.delete(key: key);
}

/// Wipes everything this app stored on the device (used on account deletion).
Future<void> wipeLocalAppData() async {
  await _secureStorage.deleteAll();
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}
