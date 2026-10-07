import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStorage {
  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> clear();
}

/// Keeps the auth token in the Android Keystore-backed secure storage
/// (Keychain on iOS), with an in-memory copy so each request doesn't hit
/// the keystore.
class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;
  String? _cachedToken;
  bool _loaded = false;

  @override
  Future<String?> readToken() async {
    if (!_loaded) {
      _cachedToken = await _storage.read(key: _tokenKey);
      _loaded = true;
    }
    return _cachedToken;
  }

  @override
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    _cachedToken = token;
    _loaded = true;
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    _cachedToken = null;
    _loaded = true;
  }
}
