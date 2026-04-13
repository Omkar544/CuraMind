import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../widgets/custom_button.dart';
import '../services/notification_service.dart';
import '../config/api_config.dart'; // Integrated for physical device connectivity

class AppointmentBookScreen extends StatefulWidget {
  final Map<String, dynamic>?
      existingData; // Passed when editing an existing record
  final String initialMode; // 'appointment' or 'medicine'

  const AppointmentBookScreen({
    super.key,
    this.existingData,
    this.initialMode = 'appointment',
  });

  @override
  State<AppointmentBookScreen> createState() => _AppointmentBookScreenState();
}

class _AppointmentBookScreenState extends State<AppointmentBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _activeTab;
  bool _isSaving = false;
  bool _isAlertEnabled = true;

  // Controllers for dynamic input handling
  final _nameController =
      TextEditingController(); // Doctor Name OR Medicine Name
  final _detailController = TextEditingController(); // Specialty OR Dosage
  final _dateController = TextEditingController(); // Only for Appointments
  final _timeController = TextEditingController(); // Alarm/Visit Time

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialMode;

    // Check if we are in "Update Mode" and pre-fill controllers
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _activeTab = data['type'] ?? widget.initialMode;

      if (_activeTab == 'appointment') {
        _nameController.text = data['doctor_name'] ?? "";
        _detailController.text = data['specialty'] ?? "";
        _dateController.text = data['date'] ?? "";
        _timeController.text = data['time'] ?? "";
      } else {
        _nameController.text = data['medicine_name'] ?? "";
        _detailController.text = data['dosage'] ?? "";
        _timeController.text = data['time'] ?? data['medicine_time'] ?? "";
      }
      _isAlertEnabled = data['alert_enabled'] ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // --- 📅 Date & Time Selectors ---

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(
          () => _dateController.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _timeController.text = picked.format(context));
    }
  }

  // --- 📡 Backend Submission Logic ---

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');

      if (userId == null) {
        _showSnackBar("Identity missing. Please log in again.", isError: true);
        return;
      }

      // 1. Construct Payload for MongoDB
      // Uses a manual IST offset (UTC+5:30) for reliable sorting in LifeLog Hub
      final Map<String, dynamic> payload = {
        "user_id": userId,
        "type": _activeTab,
        "alert_enabled": _isAlertEnabled,
        "timestamp_ref": DateTime.now()
            .toUtc()
            .add(const Duration(hours: 5, minutes: 30))
            .toIso8601String(),
      };

      if (_activeTab == 'appointment') {
        payload.addAll({
          "doctor_name": _nameController.text.trim(),
          "specialty": _detailController.text.trim(),
          "date": _dateController.text.trim(),
          "time": _timeController.text.trim(),
        });
      } else {
        payload.addAll({
          "medicine_name": _nameController.text.trim(),
          "dosage": _detailController.text.trim(),
          "time": _timeController.text.trim(),
        });
      }

      // 2. Resolve URL via ApiConfig
      final bool isUpdate = widget.existingData != null;
      final String docId = isUpdate ? widget.existingData!['_id'] : "";
      final String url = isUpdate
          ? '${ApiConfig.careClockUrl}/update/$docId'
          : '${ApiConfig.careClockUrl}/save';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 3. Schedule the "Ringing" Local Notification if enabled
        if (_isAlertEnabled) {
          await NotificationService().scheduleNotification(
            id: DateTime.now().millisecondsSinceEpoch % 100000,
            title: _activeTab == 'appointment'
                ? "Doctor Appointment"
                : "Time for Medicine",
            body: _activeTab == 'appointment'
                ? "Visit Dr. ${_nameController.text} (${_detailController.text})"
                : "Take your ${_nameController.text} dose: ${_detailController.text}",
            timeStr: _timeController.text, // e.g., "10:30 PM"
            dateStr: _activeTab == 'appointment' ? _dateController.text : null,
          );
        }

        if (mounted) {
          _showSnackBar(
              isUpdate ? "Schedule Updated!" : "Syncing to LifeLog Hub... ✅");
          // Return 'true' to trigger an auto-refresh on the previous screen
          Navigator.pop(context, true);
        }
      } else {
        _showSnackBar("Hub Error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connectivity Error: Ensure backend is on --host 0.0.0.0",
          isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
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
    final bool isUpdate = widget.existingData != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isUpdate ? "Edit Entry" : "CareClock Planner",
            style: AppStyles.headingStyle.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUpdate) _buildTypeToggle(),
              const SizedBox(height: 32),
              _buildFormFields(),
              const SizedBox(height: 32),
              _buildAlertToggle(),
              const SizedBox(height: 48),
              _isSaving
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryTeal))
                  : CustomButton(
                      text: isUpdate ? "Apply Updates" : "Save & Set Alarm",
                      onPressed: _handleSave,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _toggleItem("appointment", "Doctor", LucideIcons.user),
          _toggleItem("medicine", "Medicine", LucideIcons.pill),
        ],
      ),
    );
  }

  Widget _toggleItem(String type, String label, IconData icon) {
    bool active = _activeTab == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeTab = type;
          _nameController.clear();
          _detailController.clear();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: active ? Colors.white : Colors.grey),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                      color: active ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    bool isAppt = _activeTab == "appointment";
    return Column(
      children: [
        _buildTextField(
          _nameController,
          isAppt ? "Doctor's Full Name" : "Medicine Name",
          isAppt ? LucideIcons.user : LucideIcons.pill,
        ),
        _buildTextField(
          _detailController,
          isAppt
              ? "Specialty (e.g. Neurologist)"
              : "Dosage (e.g. 500mg or 1 Tab)",
          isAppt ? LucideIcons.stethoscope : LucideIcons.layers,
        ),
        if (isAppt)
          _buildClickableField(_dateController, "Schedule Date",
              LucideIcons.calendar, _selectDate),
        _buildClickableField(
          _timeController,
          isAppt ? "Visit Time" : "Daily Alarm Time",
          LucideIcons.alarmClock,
          _selectTime,
        ),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        style: const TextStyle(fontSize: 14),
        decoration: AppStyles.inputDecoration.copyWith(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: AppColors.iconColor),
        ),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _buildClickableField(TextEditingController ctrl, String label,
      IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        readOnly: true,
        onTap: onTap,
        style: const TextStyle(fontSize: 14),
        decoration: AppStyles.inputDecoration.copyWith(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: AppColors.iconColor),
        ),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _buildAlertToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.1)),
      ),
      child: SwitchListTile(
        title: const Text("Device Ringing Alert",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text("Receive a system notification at the set time.",
            style: TextStyle(fontSize: 11)),
        value: _isAlertEnabled,
        activeColor: AppColors.primaryTeal,
        secondary: Icon(LucideIcons.bellRing,
            color: _isAlertEnabled ? AppColors.primaryTeal : Colors.grey),
        onChanged: (v) => setState(() => _isAlertEnabled = v),
      ),
    );
  }
}
