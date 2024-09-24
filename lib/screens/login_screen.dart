import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/screens/home_screen.dart';
import 'package:kubrick/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final RecordingsController recordingsController = Get.find<RecordingsController>();
  bool isObscure = true;

  void login() async {
    try {
      final email = _emailController.text;
      final password = _passwordController.text;

      if (email == '' || password == '') {
        Get.snackbar('Error', 'Email or Password cannot be empty', colorText: Colors.white, backgroundColor: Colors.red);
        return;
      }

      final payload = await _authService.login(_emailController.text, _passwordController.text);
      final token = payload['token'];
      final expiry = payload['expires_at'];
      final userId = payload['user_id'];

      if(payload.isEmpty) {
        Get.snackbar('Error', 'Invalid email or password', colorText: Colors.white, backgroundColor: Colors.red);
        return;
      }

      await _authService.storeToken(token!, DateTime.parse(expiry!), userId!, email ?? '');

      await recordingsController.fetchRecordings();

      Get.off(() => const HomeScreen());
      print('Navigated to HomeScreen');
    } catch (e) {
      // Show an error message
      print('Error: $e');
      Get.snackbar('Error', 'An error occurred: $e', colorText: Colors.white, backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email'
              ),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscure ? Icons.visibility : Icons.visibility_off
                  ),
                  onPressed: () {
                    setState(() {
                      isObscure = !isObscure;
                    });
                  },
                )
              ),
              obscureText: isObscure,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: login,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                textStyle: const TextStyle(fontSize: 18.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}