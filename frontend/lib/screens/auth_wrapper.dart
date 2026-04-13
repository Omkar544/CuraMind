import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curamind/screens/main_wrapper.dart';
import 'package:curamind/screens/login_page.dart';
import 'package:curamind/utils/app_colors.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// Verifies if a valid session exists in SharedPreferences
  Future<void> _checkLoginStatus() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // 1. Retrieve the token and user_id stored during login/registration
      final String? token = prefs.getString('auth_token');
      final String? userId = prefs.getString('user_id');

      setState(() {
        // 2. SAFE CHECK: Ensure token is not null AND not empty.
        // Also ensure user_id exists so modules like LifeLog Hub can fetch data immediately.
        _isLoggedIn = (token != null && token.isNotEmpty) &&
            (userId != null && userId.isNotEmpty);
        _isLoading = false;
      });

      if (_isLoggedIn) {
        print("🔐 AuthWrapper: Valid session found for User ID: $userId");
      } else {
        print("🔓 AuthWrapper: No valid session. Redirecting to Login.");
      }
    } catch (e) {
      print("🚨 AuthWrapper Error: $e");
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show a splash-like loading indicator while checking the disk for keys
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryTeal,
          ),
        ),
      );
    } else {
      // If session is valid, enter the app dashboard; otherwise, show login
      return _isLoggedIn ? const MainWrapper() : const LoginPage();
    }
  }
}
