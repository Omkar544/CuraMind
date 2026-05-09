import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../widgets/custom_button.dart';
//import '../services/notification_service.dart';
import '../config/api_config.dart';

class AppointmentBookScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String initialMode;

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

  final _nameController = TextEditingController();
  final _detailController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialMode;

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

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

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
        
        

        if (mounted) {
          _showSnackBar(
              isUpdate ? "Schedule Updated!" : "Syncing to LifeLog Hub... ✅");
          Navigator.pop(context, true);
        }
      } else {
        _showSnackBar("Hub Error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connectivity Error: Ensure backend is running",
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

  Widget _buildFormFields() {
    bool isAppt = _activeTab == "appointment";

    return Column(
      children: [
        _buildNameField(isAppt),
        isAppt ? _buildSpecialtyDropdown() : _buildDosageDropdown(),
        if (isAppt)
          _buildClickableField(_dateController, "Schedule Date",
              LucideIcons.calendar, _selectDate),
        _buildClickableField(
            _timeController,
            isAppt ? "Visit Time" : "Daily Alarm Time",
            LucideIcons.alarmClock,
            _selectTime),
      ],
    );
  }

  Widget _buildNameField(bool isAppt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _nameController,
        decoration: AppStyles.inputDecoration.copyWith(
          labelText: isAppt ? "Doctor's Full Name" : "Medicine Name",
          prefixIcon: Icon(isAppt ? LucideIcons.user : LucideIcons.pill,
              size: 20, color: AppColors.iconColor),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return "Required";

          if (isAppt && !RegExp(r'^[a-zA-Z\s]+$').hasMatch(v)) {
            return "Only alphabets allowed";
          }

          return null;
        },
      ),
    );
  }

  Widget _buildSpecialtyDropdown() {
    final specialties = [
      "Cardiologist",
      "Dermatologist",
      "Neurologist",
      "Orthopedic",
      "Pediatrician",
      "Gynecologist",
      "Psychiatrist",
      "Dentist",
      "Ophthalmologist",
      "ENT Specialist",
      "Oncologist",
      "Radiologist",
      "General Physician",
      "Urologist",
      "Gastroenterologist",
      "Pulmonologist",
      "Endocrinologist",
      "Nephrologist",
      "Surgeon"
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: specialties.contains(_detailController.text)
            ? _detailController.text
            : null,
        decoration: AppStyles.inputDecoration.copyWith(
          labelText: "Doctor Specialty",
          prefixIcon: Icon(LucideIcons.stethoscope),
        ),
        items: specialties
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => _detailController.text = v!,
        validator: (v) => v == null ? "Required" : null,
      ),
    );
  }

  Widget _buildDosageDropdown() {
    final dosages = [
      "1 mg",
      "2 mg",
      "5 mg",
      "10 mg",
      "25 mg",
      "50 mg",
      "100 mg",
      "250 mg",
      "500 mg",
      "1 Tablet",
      "2 Tablets",
      "1 Capsule",
      "2 Capsules",
      "5 ml",
      "10 ml"
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: dosages.contains(_detailController.text)
            ? _detailController.text
            : null,
        decoration: AppStyles.inputDecoration.copyWith(
          labelText: "Dosage",
          prefixIcon: Icon(LucideIcons.layers),
        ),
        items: dosages
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => _detailController.text = v!,
        validator: (v) => v == null ? "Required" : null,
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
        decoration: AppStyles.inputDecoration.copyWith(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: AppColors.iconColor),
        ),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
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
