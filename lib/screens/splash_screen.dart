import 'package:flutter/material.dart';
import 'package:kubrick/services/auth_service.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void checkToken(BuildContext context) async {
    final sessionData = await AuthService().getToken();
    final token = sessionData['auth_token'];
    final expiresAtString = sessionData['expires_at'];

    if (token != null && expiresAtString != null) {
      try {
        final expiresAt = DateTime.parse(expiresAtString);
        if (isTokenValid(token, expiresAt)) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  bool isTokenValid(String token, DateTime expiresAt) {
    return token.isNotEmpty && DateTime.now().isBefore(expiresAt);
  }

  @override
  Widget build(BuildContext context) {
    checkToken(context);
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}