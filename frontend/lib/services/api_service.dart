import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart'; // <--- IMPORT THE NEW CONFIG

class ApiService {
  // Now uses the centralized config
  static const String baseUrl = ApiConfig.baseUrl;

  // 1. UPDATE PROFILE (Age/Weight in PostgreSQL)
  static Future<bool> updateProfile(int? age, double? weight) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/auth/update-profile/$userId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        if (age != null) "age": age,
        if (weight != null) "weight_kg": weight,
      }),
    );

    return response.statusCode == 200;
  }

  // 2. DELETE CARECLOCK ITEM (Medicine/Appointment in MongoDB)
  static Future<bool> deleteCareClockItem(String docId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/careclock/delete/$docId?user_id=$userId'),
    );

    return response.statusCode == 200;
  }

  // 3. UPDATE CARECLOCK ITEM (Medicine/Appointment in MongoDB)
  static Future<bool> updateCareClockItem(
      String docId, Map<String, dynamic> newData) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/careclock/update/$docId?user_id=$userId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(newData),
    );

    return response.statusCode == 200;
  }
}
