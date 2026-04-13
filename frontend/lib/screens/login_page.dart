import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../utils/app_colors.dart';
import '../utils/app_styles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for authentication
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Use 10.0.2.2 for Android Emulator. Update to your laptop's IPv4 for physical mobile testing.
  final String _apiBaseUrl = 'http://10.0.2.2:8000';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 🔐 AUTH LOGIC: Connects to PostgreSQL via FastAPI
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final Map<String, String> loginData = {
      "username": _usernameController.text.trim(),
      "password": _passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(loginData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 💾 SAVE SESSION: These keys are strictly read by LifelogScreen and Home
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['access_token'] ?? '');
        await prefs.setString('user_id', data['user_id'] ?? '');
        await prefs.setString('user_name', data['user_name'] ?? 'User');

        print("🔑 Login Successful! User UUID: ${data['user_id']}");

        if (mounted) {
          _showSnackBar("Welcome back, ${data['user_name']}!", isError: false);
          Navigator.pushReplacementNamed(context, '/main_wrapper');
        }
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _errorMessage = errorData['detail'] ?? "Invalid username or password";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection refused. Is the FastAPI server running?";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Branding ---
                  const Icon(
                    LucideIcons.brainCircuit,
                    size: 72,
                    color: AppColors.primaryTeal,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "CuraMind",
                    textAlign: TextAlign.center,
                    style: AppStyles.headingStyle.copyWith(
                      color: AppColors.primaryTeal,
                      fontSize: 34,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Log in to your AI wellness companion",
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyStyle
                        .copyWith(color: AppColors.textGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 48),

                  // --- Fields ---
                  TextFormField(
                    controller: _usernameController,
                    decoration: AppStyles.inputDecoration.copyWith(
                      labelText: "Username",
                      prefixIcon: const Icon(LucideIcons.user,
                          color: AppColors.iconColor, size: 20),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Username required" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: AppStyles.inputDecoration.copyWith(
                      labelText: "Password",
                      prefixIcon: const Icon(LucideIcons.lock,
                          color: AppColors.iconColor, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? LucideIcons.eye
                              : LucideIcons.eyeOff,
                          color: AppColors.iconColor,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Password required" : null,
                  ),

                  // --- Error Display ---
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.errorRed.withOpacity(0.2)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // --- Action ---
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primaryTeal))
                      : ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                          ),
                          child: const Text("Log In",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("New to CuraMind? ",
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: const Text(
                          "Create Account",
                          style: TextStyle(
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
