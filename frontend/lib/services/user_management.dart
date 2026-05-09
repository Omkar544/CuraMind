import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class UserManagementService {
  // Configured for your current physical device IP
  static const String _apiBaseUrl = 'http://172.20.10.4:8000';

  /// Handles the "Clean Slate" process:
  /// 1. Tells backend to delete PG & Mongo data.
  /// 2. Wipes local SharedPreferences.
  /// 3. Returns user to registration.
  static Future<void> deleteAccountAndClearCache(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');

      // If no ID is found locally, just clear cache and boot to register
      if (userId == null || userId.isEmpty) {
        await prefs.clear();
        if (context.mounted) _navigateToRegister(context);
        return;
      }

      // 1. Backend Wipe with Timeout and Headers
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/api/auth/delete/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 2. Local Cache Wipe
        await prefs.clear();

        if (context.mounted) {
          _showStatus(context, "Account and data successfully wiped.",
              isError: false);
          _navigateToRegister(context);
        }
      } else {
        // Handle specific backend errors (e.g., 404, 500)
        if (context.mounted) {
          _showStatus(context,
              "Server error (${response.statusCode}). Please try again later.");
        }
      }
    } on SocketException {
      if (context.mounted)
        _showStatus(context, "No internet connection or server unreachable.");
    } on HttpException {
      if (context.mounted)
        _showStatus(context, "Couldn't find the requested service.");
    } catch (e) {
      debugPrint("🚨 Error during cleanup: $e");
      if (context.mounted)
        _showStatus(context, "An unexpected error occurred.");
    }
  }

  // Helper to standardise navigation
  static void _navigateToRegister(BuildContext context) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/register', (route) => false);
  }

  // Helper to standardise SnackBar feedback
  static void _showStatus(BuildContext context, String message,
      {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
