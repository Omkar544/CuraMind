import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../config/api_config.dart'; // Centralized IP configuration

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the mandatory identity/auth fields (10 total including Confirm Pwd)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedGender;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Uses the centralized configuration for physical device connectivity
  final String _apiBaseUrl = ApiConfig.rootUrl;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 🛡️ REGISTRATION LOGIC: Persists fields to PostgreSQL and initiates session
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final Map<String, dynamic> registrationData = {
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "age": int.tryParse(_ageController.text.trim()) ?? 0,
      "gender": _selectedGender?.toLowerCase() ?? "other",
      "weight_kg": double.tryParse(_weightController.text.trim()) ?? 0.0,
      "phone_number": _phoneController.text.trim(),
      "email": _emailController.text.trim(),
      "username": _usernameController.text.trim(),
      "password": _passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/auth/register'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(registrationData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // 💾 PERSIST SESSION: These keys are critical for the LifeLog Hub history sync
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['access_token'] ?? '');
        await prefs.setString('user_id', data['user_id'] ?? '');
        await prefs.setString(
            'user_name', data['user_name'] ?? _firstNameController.text.trim());

        if (mounted) {
          _showSnackBar("Registration Successful! Welcome to CuraMind.",
              isError: false);
          // Navigate to main wrapper and clear the navigation stack
          Navigator.pushReplacementNamed(context, '/main_wrapper');
        }
      } else {
        final errorData = json.decode(response.body);
        _showError(errorData['detail'] ??
            "Registration failed. Try a different username.");
      }
    } catch (e) {
      _showError(
          "Connection refused. Ensure the FastAPI server is running on 0.0.0.0");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating),
    );
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Create Account"),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Personal Details", LucideIcons.user),
              const SizedBox(height: 16),
              _buildTextField(
                  _firstNameController, "First Name", LucideIcons.user),
              _buildTextField(
                  _lastNameController, "Last Name", LucideIcons.userCheck),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(
                          _ageController, "Age", LucideIcons.calendar,
                          isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildTextField(_weightController, "Weight (kg)",
                          LucideIcons.scale, // FIXED: Corrected icon name
                          isNumber: true)),
                ],
              ),
              _buildGenderDropdown(),
              const SizedBox(height: 32),
              _buildSectionHeader("Account Security", LucideIcons.shieldCheck),
              const SizedBox(height: 16),
              _buildTextField(
                  _phoneController, "Phone Number", LucideIcons.phone,
                  isNumber: true),
              _buildTextField(
                  _emailController, "Email Address", LucideIcons.mail),
              _buildTextField(
                  _usernameController, "Username", LucideIcons.atSign),
              _buildTextField(
                _passwordController,
                "Password",
                LucideIcons.lock,
                isPassword: true,
                showPassword: !_obscurePassword,
                onToggleVisibility: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              _buildTextField(
                _confirmPasswordController,
                "Confirm Password",
                LucideIcons.lock,
                isPassword: true,
                isConfirm: true,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryTeal))
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleRegister,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0),
                        child: const Text("Register Now",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: Text(
                    "Already have an account? Login",
                    style: TextStyle(
                        color: Colors.blueGrey.shade600,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryTeal),
        const SizedBox(width: 10),
        Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
                letterSpacing: 1.1)),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool isPassword = false,
    bool isConfirm = false,
    bool? showPassword,
    VoidCallback? onToggleVisibility,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        obscureText:
            isPassword && (showPassword == false || showPassword == null),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: AppStyles.inputDecoration.copyWith(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.iconColor, size: 20),
          suffixIcon: isPassword && onToggleVisibility != null
              ? IconButton(
                  icon: Icon(
                      showPassword! ? LucideIcons.eyeOff : LucideIcons.eye,
                      color: AppColors.iconColor,
                      size: 20),
                  onPressed: onToggleVisibility,
                )
              : null,
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return "Required";
          if (label == "Email Address" && !v.contains("@")) {
            return "Invalid email";
          }
          if (isPassword && v.length < 6) return "Min 6 characters";
          if (isConfirm && v != _passwordController.text) {
            return "Passwords do not match";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: AppStyles.inputDecoration.copyWith(
          labelText: "Gender",
          prefixIcon: const Icon(LucideIcons.users,
              color: AppColors.iconColor, size: 20),
        ),
        items: ["Male", "Female", "Other"]
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (v) => setState(() => _selectedGender = v),
        validator: (v) => v == null ? "Select Gender" : null,
      ),
    );
  }
}
