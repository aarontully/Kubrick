import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  AuthService authService = AuthService();

  Get.put(SharedState());
  Get.put(RecordingsController());
  runApp(
    GetMaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 72,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 56,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 30,
            fontWeight: FontWeight.w700
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Montserrat',
          ),
          bodySmall: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ),
      home: FutureBuilder<void>(
        future: authService.checkToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
      debugShowCheckedModeBanner: false
    ),
  );
}

//This cant stay in production, it will make the app vulnerable to attacks
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}