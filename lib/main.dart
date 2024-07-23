import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/screens/home_screen.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();

  Get.put(SharedState());
  Get.put(RecordingsController());
  runApp(const MaterialApp(home: HomeScreen()));
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