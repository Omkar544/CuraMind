import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class UserManagementService {
  // Use 10.0.2.2 for emulator. Update to your Laptop IP (172.20.10.4) for physical device.
  static const String _apiBaseUrl = 'http://172.20.10.4:8000';

  /// Handles the "Clean Slate" process:
  /// 1. Tells backend to delete PG & Mongo data.
  /// 2. Wipes local SharedPreferences.
  /// 3. Returns user to registration.
  static Future<void> deleteAccountAndClearCache(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');

      if (userId == null) {
        await prefs.clear();
        _navigateToRegister(context);
        return;
      }

      // 1. Backend Wipe
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/api/auth/delete/$userId'),
      );

      if (response.statusCode == 200) {
        // 2. Local Cache Wipe
        await prefs.clear();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account and local cache cleared.")),
          );
          _navigateToRegister(context);
        }
      }
    } catch (e) {
      debugPrint("🚨 Error during cleanup: $e");
    }
  }

  static void _navigateToRegister(BuildContext context) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/register', (route) => false);
  }
}
