import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;

  final String _apiBaseUrl = ApiConfig.rootUrl;

  @override
  void initState() {
    super.initState();
    _loadUserFromBackend();
  }

  // ✅ LOAD USER DATA FROM POSTGRES
  Future<void> _loadUserFromBackend() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) return;

    final response =
        await http.get(Uri.parse('$_apiBaseUrl/api/auth/profile/$userId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      _firstNameController.text = data['first_name'] ?? '';
      _lastNameController.text = data['last_name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _ageController.text = data['age'].toString();
      _weightController.text = data['weight_kg'].toString();
    }

    setState(() => _isLoading = false);
  }

  // ✅ UPDATE PROFILE IN DATABASE
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) return;

    final response = await http.put(
      Uri.parse('$_apiBaseUrl/api/auth/update-profile/$userId'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "first_name": _firstNameController.text,
        "last_name": _lastNameController.text,
        "email": _emailController.text,
        "age": int.tryParse(_ageController.text),
        "weight_kg": double.tryParse(_weightController.text),
      }),
    );

    if (response.statusCode == 200) {
      await prefs.setString('user_name', _firstNameController.text);

      setState(() => _isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile Updated Successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Update Failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ DELETE ACCOUNT FROM BACKEND
  Future<void> _deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) return;

    await http.delete(
      Uri.parse('$_apiBaseUrl/api/auth/delete/$userId'),
    );

    await prefs.clear();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/register', (route) => false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("This will permanently remove your account."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile & Settings"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ✅ DARK MODE
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (_, currentMode, __) {
                return SwitchListTile(
                  title: const Text("Dark Mode"),
                  value: currentMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeNotifier.value =
                        value ? ThemeMode.dark : ThemeMode.light;
                  },
                );
              },
            ),

            const Divider(height: 30),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(_firstNameController, "First Name"),
                  _buildTextField(_lastNameController, "Last Name"),
                  _buildTextField(_emailController, "Email"),
                  _buildTextField(_ageController, "Age"),
                  _buildTextField(_weightController, "Weight"),
                  const SizedBox(height: 20),
                  _isEditing
                      ? ElevatedButton(
                          onPressed: _updateProfile,
                          child: const Text("Update Profile"),
                        )
                      : ElevatedButton(
                          onPressed: () => setState(() => _isEditing = true),
                          child: const Text("Edit Profile"),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                "Delete Account",
                style: TextStyle(color: Colors.red),
              ),
              onTap: _confirmDelete,
            ),
          ],
        ),
      ),
    );
  }
}
