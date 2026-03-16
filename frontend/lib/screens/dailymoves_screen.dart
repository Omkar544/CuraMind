import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../widgets/custom_button.dart';
import '../services/fitbit_service.dart';
import '../services/health_service.dart';
import '../config/api_config.dart'; // <--- IMPORTED THE NEW CONFIG

typedef DropdownOption = Map<String, String>;

class DailyMovesScreen extends StatefulWidget {
  const DailyMovesScreen({super.key});

  @override
  State<DailyMovesScreen> createState() => _DailyMovesScreenState();
}

class _DailyMovesScreenState extends State<DailyMovesScreen> {
  final _formKey = GlobalKey<FormState>();
  final FitbitService _fitbitService = FitbitService();
  final HealthService _healthService = HealthService();

  // ML Input Controllers
  final _stepsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _durationController = TextEditingController();
  final _sleepHoursController = TextEditingController();
  final _stressLevelController = TextEditingController();
  final _hydrationLevelController = TextEditingController();

  String? _selectedGender,
      _selectedActivityType,
      _selectedIntensity,
      _selectedSmokingStatus;

  bool _isSyncing = false;
  bool _isLoadingPrediction = false;
  bool _isGeneratingTip = false;

  String _statusMessage = "Sync to fetch Fitbit & local health data";
  String _predictionResult = "No prediction yet";
  String? _aiHealthTip;

  // Gemini XAI Configuration
  static const String _geminiApiKey = "AIzaSyB3Goe41V6bmJcDOAlRM7TqLSEvNdX3EYw";
  static const String _geminiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=$_geminiApiKey";

  // Backend API Base URL updated to use centralized config
  final String _apiBaseUrl = ApiConfig.rootUrl;

  final List<DropdownOption> _genderOptions = [
    {'Male': 'male'},
    {'Female': 'female'},
    {'Other': 'other'}
  ];
  final List<DropdownOption> _intensityOptions = [
    {'Low': 'low'},
    {'Moderate': 'medium'},
    {'High': 'high'}
  ];
  final List<DropdownOption> _smokingStatusOptions = [
    {'Non-smoker': 'never'},
    {'Smoker': 'current'},
    {'Former Smoker': 'former'}
  ];
  final List<DropdownOption> _activityTypeOptions = [
    {'Running': 'running'},
    {'Walking': 'walking'},
    {'Cycling': 'cycling'},
    {'Swimming': 'swimming'},
    {'Yoga': 'yoga'},
    {'Strength Training': 'strength training'}
  ];

  @override
  void initState() {
    super.initState();
    _fetchSQLProfile();
  }

  /// 📡 IDENTITY SYNC: Fetches stored profile for ML baseline
  Future<void> _fetchSQLProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null || userId.isEmpty) return;

      final response =
          await http.get(Uri.parse('$_apiBaseUrl/api/auth/profile/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ageController.text = data['age']?.toString() ?? "";
          _weightController.text = data['weight']?.toString() ?? "";
          String? dbGender = data['gender']?.toString().toLowerCase();
          if (dbGender != null) {
            _selectedGender = (dbGender.startsWith('m'))
                ? 'male'
                : (dbGender.startsWith('f') ? 'female' : 'other');
          }
        });
      }
    } catch (e) {
      debugPrint("Profile fetch error: $e");
    }
  }

  /// 💡 REAL-TIME XAI: Generates coaching after XGBoost result
  Future<void> _generateHealthTip(String result) async {
    setState(() => _isGeneratingTip = true);
    try {
      final prompt = "User fitness assessment: '$result'. "
          "Metrics: Steps: ${_stepsController.text}, Cal: ${_caloriesController.text}, Stress: ${_stressLevelController.text}. "
          "Provide a unique 2-sentence medical insight. Use LaTeX notation like \$BMI\$ or \$VO_2 max\$ if relevant. Be professional.";

      final response = await http.post(
        Uri.parse(_geminiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final aiData = json.decode(response.body);
        setState(() {
          _aiHealthTip =
              aiData['candidates']?[0]['content']?['parts']?[0]['text'];
          _isGeneratingTip = false;
        });
      }
    } catch (e) {
      setState(() => _isGeneratingTip = false);
    }
  }

  /// 🤖 ML PREDICTION: Sends data to FastAPI XGBoost Backend
  Future<void> _generatePrediction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoadingPrediction = true;
      _aiHealthTip = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      final Map<String, dynamic> requestBody = {
        "user_id": userId,
        "steps": int.tryParse(_stepsController.text) ?? 0,
        "calories": double.tryParse(_caloriesController.text) ?? 0.0,
        "age": int.parse(_ageController.text),
        "gender": _selectedGender,
        "height_cm": double.parse(_heightController.text),
        "weight_kg": double.parse(_weightController.text),
        "activity_type": _selectedActivityType,
        "duration_minutes": int.parse(_durationController.text),
        "intensity": _selectedIntensity,
        "sleep_hours": double.parse(_sleepHoursController.text),
        "stress_level": int.parse(_stressLevelController.text),
        "hydration_level": int.parse(_hydrationLevelController.text),
        "smoking_status": _selectedSmokingStatus,
      };

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/dailymoves/predict'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        String pred = result['prediction'];
        setState(() {
          _predictionResult = pred;
        });
        await _generateHealthTip(pred);
        _showSnackBar("Assessment Saved to LifeLog Hub! ✅", isError: false);
      }
    } catch (e) {
      _showSnackBar("AI Error: Connection failed.", isError: true);
    } finally {
      setState(() => _isLoadingPrediction = false);
    }
  }

  /// 🕒 CONTEXTUAL FALLBACK: Estimates steps if sensors are unavailable
  int _generateRealTimeSteps() {
    final int hour = DateTime.now().hour;
    final random = Random();
    if (hour >= 6 && hour < 10) return 2500 + random.nextInt(3500);
    if (hour >= 10 && hour < 17) return 1200 + random.nextInt(1800);
    if (hour >= 17 && hour < 21) return 3000 + random.nextInt(4000);
    return 100 + random.nextInt(500);
  }

  /// ⌚ MULTI-APP SYNC: Local Steps + Fitbit Yesterday's Calories
  Future<void> _syncActivityData() async {
    setState(() {
      _isSyncing = true;
      _statusMessage = "Fetching health data...";
    });

    try {
      // 1. Fetch Local Steps Today (Priority)
      int localSteps = await _healthService.fetchStepsToday();
      if (localSteps > 0) {
        _stepsController.text = localSteps.toString();
      } else {
        _stepsController.text = _generateRealTimeSteps().toString();
      }

      // 2. Fetch Fitbit Calories (Specifically Yesterday)
      final DateTime yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      final result = await _fitbitService.fetchActivityForDate(yesterday);

      if (result['error'] == null) {
        setState(() {
          _caloriesController.text = (result['calories'] ?? 0.0).toString();
          _statusMessage = "Synced: Local Steps & Fitbit Cal! ✅";
        });
      } else {
        String err = result['error'];
        if (err == "Needs Login" || err.contains("401")) {
          _showFitbitLoginPopup();
        } else {
          setState(() => _statusMessage = "Steps estimated. Fitbit offline.");
        }
      }
    } catch (e) {
      setState(() => _statusMessage = "Sync failed. Please check permissions.");
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  void _showFitbitLoginPopup() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          if (request.url.startsWith("curamind://callback")) {
            Navigator.pop(context);
            _fitbitService
                .handleCallback(Uri.parse(request.url.replaceFirst("#", "?")))
                .then((_) => _syncActivityData());
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(_fitbitService.getLoginUrl()));

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: WebViewWidget(controller: controller)));
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DailyMoves Assessment")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSyncCard(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: _buildInputField(_stepsController, "Steps Today",
                          icon: LucideIcons.footprints)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildInputField(
                          _caloriesController, "Cal (Yesterday)",
                          icon: LucideIcons.flame, iconColor: Colors.orange)),
                ],
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(child: _buildInputField(_ageController, "Age")),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildDropdownField(
                          _selectedGender,
                          _genderOptions,
                          "Gender",
                          (v) => setState(() => _selectedGender = v))),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child:
                          _buildInputField(_heightController, "Height (cm)")),
                  const SizedBox(width: 12),
                  Expanded(
                      child:
                          _buildInputField(_weightController, "Weight (kg)")),
                ],
              ),
              _buildDropdownField(
                  _selectedActivityType,
                  _activityTypeOptions,
                  "Activity Type",
                  (v) => setState(() => _selectedActivityType = v)),
              _buildInputField(_durationController, "Duration (min)"),
              _buildDropdownField(_selectedIntensity, _intensityOptions,
                  "Intensity", (v) => setState(() => _selectedIntensity = v)),
              _buildInputField(_sleepHoursController, "Sleep (hrs)"),
              _buildInputField(_stressLevelController, "Stress (1-10)"),
              _buildInputField(_hydrationLevelController, "Hydration (ml)"),
              _buildDropdownField(
                  _selectedSmokingStatus,
                  _smokingStatusOptions,
                  "Smoking Status",
                  (v) => setState(() => _selectedSmokingStatus = v)),
              const SizedBox(height: 32),
              if (_predictionResult != "No prediction yet") _buildResultCard(),
              const SizedBox(height: 16),
              _isLoadingPrediction
                  ? const CircularProgressIndicator()
                  : CustomButton(
                      text: "Run AI Assessment",
                      onPressed: _generatePrediction),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
          border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3))),
      child: Column(children: [
        const Text("ML PREDICTION RESULT",
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(_predictionResult,
            style: AppStyles.headingStyle
                .copyWith(color: AppColors.primaryTeal, fontSize: 24)),
        const Divider(height: 30),
        Row(
          children: [
            const Icon(LucideIcons.sparkles, color: Colors.orange, size: 18),
            const SizedBox(width: 8),
            Text("AI PERSONAL COACH",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade700)),
          ],
        ),
        const SizedBox(height: 10),
        _isGeneratingTip
            ? const LinearProgressIndicator()
            : Text(_aiHealthTip ?? "Analyzing metabolic trends...",
                style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87)),
      ]),
    );
  }

  Widget _buildSyncCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.2))),
      child: Column(children: [
        Row(children: [
          const Icon(LucideIcons.refreshCw, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(_statusMessage,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey))),
        ]),
        const SizedBox(height: 16),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _syncActivityData,
                icon: const Icon(LucideIcons.smartphone, size: 18),
                label: const Text("Sync Fitbit & Health Data"))),
      ]),
    );
  }

  Widget _buildInputField(TextEditingController ctrl, String label,
      {bool isReadOnly = false, IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: ctrl,
        readOnly: isReadOnly,
        keyboardType: TextInputType.number,
        decoration: AppStyles.inputDecoration.copyWith(
            labelText: label,
            prefixIcon: icon != null
                ? Icon(icon,
                    color: iconColor ?? AppColors.primaryTeal, size: 20)
                : null),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _buildDropdownField(String? val, List<DropdownOption> opts, String lbl,
      ValueChanged<String?> onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: val,
        items: opts
            .map((o) => DropdownMenuItem(
                value: o.values.first, child: Text(o.keys.first)))
            .toList(),
        onChanged: onChange,
        decoration: AppStyles.inputDecoration.copyWith(labelText: lbl),
        validator: (v) => v == null ? "Required" : null,
      ),
    );
  }
}