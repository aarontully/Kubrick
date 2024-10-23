import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/screens/login_screen.dart';

class AuthService {
  final String apiUrl = 'https://transcription.staging.endemolshine.com.au/api/v1'; // Replace with the API URL
  final storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$apiUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data']['session']; // Return the token
    } else {
      print('Failed to login: ${response.body}');
      return {};
    }
  }

  Future<void> storeToken(String token, DateTime expiresAt, String userId, String email) async {
    try {
      await storage.write(key: 'auth_token', value: token);
      await storage.write(key: 'expires_at', value: expiresAt.toIso8601String());
      await storage.write(key: 'user_id', value: userId);
      await storage.write(key: 'email', value: email);
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<Map<String?, String?>> getToken() async {
    try {
      final session = await storage.readAll();
      return session;
    } catch (e) {
      print('Error in get token: $e');
    }
    return {};
  }

  Future<String> getUserId() async {
    final sessionData = await getToken();
    return sessionData['user_id'] ?? '';
  }

  Future<String> getEmail() async {
    final sessionData = await getToken();
    return sessionData['email'] ?? '';
  }

  Future<void> logout() async {
    print('Logged out');
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'expires_at');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'email');
    Get.find<RecordingsController>().recordings.clear();
    Get.off(() => const LoginScreen());
  }
}