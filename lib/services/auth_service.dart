import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:kubrick/screens/home_screen.dart';
import 'package:kubrick/screens/login_screen.dart';

class AuthService {
  final String apiUrl = 'https://transcription.staging.endemolshine.com.au/api/v1'; // Replace with the API URL
  final storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  //SharedState sharedState = Get.find<SharedState>();

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

  Future<void> storeToken(String token, DateTime expiresAt, String userId) async {
    try {
      await storage.write(key: 'auth_token', value: token);
      await storage.write(key: 'expires_at', value: expiresAt.toIso8601String());
      await storage.write(key: 'user_id', value: userId);
      print('Token stored: $token, It will expire on: $expiresAt for user: $userId');
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<Map<String?, String?>> getToken() async {
    try {
      final session = await storage.readAll();
      print('Token fetched: ${session['auth_token']}, It will expire on: ${session['expires_at']}');
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

  /* Future<void> checkToken() async {
    final sessionData = await getToken();
    final token = sessionData['auth_token'];
    final expiresAtStr = sessionData['expires_at'];
    if (token == null || expiresAtStr == null) {
      Get.off(() => const LoginScreen());
      return;
    }

    final expiresAt = DateTime.parse(expiresAtStr);
    if (DateTime.now().isAfter(expiresAt)) {
      navigator.push(() => const LoginScreen());
      Get.to(() => const LoginScreen());
    } else {
      Get.to(() => const HomeScreen());
    }
  } */

  Future<void> logout() async {
    await storage.deleteAll();
    Get.off(() => const LoginScreen());
  }
}