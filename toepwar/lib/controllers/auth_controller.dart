import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/auth_storage.dart';
import '../models/user_model.dart';
import '../models/auth_model.dart';
import '../utils/api_constants.dart';

class AuthController {
  Future<User> login(String email, String password) async {
    try {
      final credentials = AuthCredentials(email: email, password: password);
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(credentials.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data);
        // Save auth data after successful login
        await AuthStorage.saveAuthData(user);
        return user;
      } else {
        throw Exception(json.decode(response.body)['detail'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  // Add logout method
  Future<void> logout() async {
    await AuthStorage.clearAuthData();
  }

  Future<void> register(String username, String email, String password) async {
    try {
      final credentials = AuthCredentials(
        email: email,
        password: password,
        username: username,
      );

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(credentials.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
          json.decode(response.body)['detail'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }
}
