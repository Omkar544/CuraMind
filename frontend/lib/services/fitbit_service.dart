import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FitbitService {
  // Confirmed Client ID for the CuraMind Fitbit App
  static const String _clientId = "23TV6Z";
  static const String _redirectUri = "curamind://callback";

  /// Generates the official Fitbit Authorization URL for OAuth 2.0.
  /// Requesting scopes for activity (steps/calories), heart rate, and sleep.
  String getLoginUrl() {
    return "https://www.fitbit.com/oauth2/authorize"
        "?response_type=token"
        "&client_id=$_clientId"
        "&redirect_uri=${Uri.encodeComponent(_redirectUri)}"
        "&scope=activity%20heartrate%20sleep"
        "&expires_in=604800"; // Token valid for 7 days
  }

  /// Extracts and stores the access_token from the redirected URL.
  Future<void> handleCallback(Uri uri) async {
    String? token;

    // Fitbit returns the token in the URL fragment (#)
    if (uri.hasFragment) {
      final Map<String, String> fragmentParameters =
          Uri.splitQueryString(uri.fragment);
      token = fragmentParameters['access_token'];
    } else if (uri.queryParameters.containsKey('access_token')) {
      token = uri.queryParameters['access_token'];
    }

    if (token != null && token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fitbit_access_token', token);
      print("✅ Fitbit Service: Authentication successful. Token stored.");
    }
  }

  /// Fetches summary activity data (Steps and Calories) for a specific date.
  /// Standardizes date formatting to 'yyyy-MM-dd' to prevent API errors.
  Future<Map<String, dynamic>> fetchActivityForDate(DateTime targetDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fitbit_access_token');

      if (token == null) {
        return {"error": "Needs Login"};
      }

      // Strict formatting: 2026-02-05
      final String formattedDate =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

      print("--- ⌚ Fitbit: Syncing Activity for $formattedDate ---");

      final response = await http.get(
        Uri.parse(
            "https://api.fitbit.com/1/user/-/activities/date/$formattedDate.json"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Accept-Language": "en_US",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final summary = data['summary'] ?? {};

        return {
          "steps": summary['steps'] ?? 0,
          "calories": summary['caloriesOut'] ?? 0,
          "error": null,
          "date": formattedDate
        };
      } else if (response.statusCode == 401) {
        // Token has expired or been revoked
        await logout();
        return {"error": "Token Expired"};
      } else {
        print("❌ Fitbit API Error: ${response.statusCode}");
        return {"error": "API Error: ${response.statusCode}"};
      }
    } catch (e) {
      print("🚨 Fitbit Connection Exception: $e");
      return {"error": "Connection Failed"};
    }
  }

  /// Wipes the Fitbit credentials from the mobile device cache.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fitbit_access_token');
    print("🗑️ Fitbit: Local session cleared.");
  }
}
