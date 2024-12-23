import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userDataKey = 'user_data';

  // Save auth token and user data
  static Future<void> saveAuthData(User user) async {
    await _storage.write(key: _tokenKey, value: user.token);
    await _storage.write(key: _userDataKey, value: json.encode(user.toJson()));
  }

  // Get saved token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get saved user data
  static Future<User?> getSavedUser() async {
    final userData = await _storage.read(key: _userDataKey);
    if (userData != null) {
      return User.fromJson(json.decode(userData));
    }
    return null;
  }

  // Clear saved auth data
  static Future<void> clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userDataKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}