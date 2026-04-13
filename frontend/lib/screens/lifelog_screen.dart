import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';

import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../config/api_config.dart'; // Centralized IP configuration
import 'appointment_book_screen.dart';

class LifelogScreen extends StatefulWidget {
  const LifelogScreen({super.key});

  @override
  State<LifelogScreen> createState() => _LifelogScreenState();
}

class _LifelogScreenState extends State<LifelogScreen> {
  // Data Buckets synced from MongoDB via FastAPI
  List<dynamic> _dailyMoves = [];
  List<dynamic> _mindEase = [];
  List<dynamic> _appointments = [];
  List<dynamic> _medicines = [];
  List<dynamic> _digitizedReports = [];

  // Local state for Dynamic AI coaching (XAI)
  final Map<String, String> _dynamicTips = {};
  final Map<String, bool> _tipLoadingState = {};

  bool _isLoading = true;
  bool _isAnalyzingDoc = false;
  String? _errorMessage;

  // Gemini XAI Configuration (Used for historical trend analysis)
  static const String _geminiApiKey = "AIzaSyB3Goe41V6bmJcDOAlRM7TqLSEvNdX3EYw";
  static const String _geminiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=$_geminiApiKey";

  @override
  void initState() {
    super.initState();
    _fetchFullHistory();
  }

  /// 📡 IDENTITY & HISTORY SYNC: Connects to the Laptop Backend
  Future<void> _fetchFullHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id')?.trim();

      if (userId == null || userId.isEmpty) {
        setState(() {
          _errorMessage = "Identity missing. Please log in again.";
          _isLoading = false;
        });
        return;
      }

      // Using ApiConfig.lifeLogUrl for physical device connectivity
      final response = await http
          .get(
            Uri.parse('${ApiConfig.lifeLogUrl}/history/$userId'),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _dailyMoves = data['daily_moves'] ?? [];
          _mindEase = data['mind_ease'] ?? [];
          _appointments = data['appointments'] ?? [];
          _medicines = data['medicines'] ?? [];
          _digitizedReports = data['digitized_reports'] ?? [];
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = "Server Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            "Connection Failed. Ensure FastAPI is running on 0.0.0.0 and Port 8000.";
        _isLoading = false;
      });
    }
  }

  /// 💡 DYNAMIC XAI: Generates personalized coaching for a specific historical record
  Future<void> _generateDynamicInsight(
      String recordId, String label, dynamic data, String result) async {
    setState(() => _tipLoadingState[recordId] = true);

    try {
      final prompt = "User has a $label assessment record. "
          "Input data: ${data.toString()}. "
          "Result: $result. "
          "Provide a unique 2-sentence medical tip based on these specific metrics. Use LaTeX notation like \$BMI\$ where appropriate. Be professional.";

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
          _dynamicTips[recordId] = aiData['candidates']?[0]['content']?['parts']
                  ?[0]['text'] ??
              "Keep active!";
          _tipLoadingState[recordId] = false;
        });
      }
    } catch (e) {
      setState(() => _tipLoadingState[recordId] = false);
    }
  }

  /// 👁️ VISION XAI: Scans physical medical reports for digitization
  Future<void> _pickAndAnalyzeDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result == null || result.files.single.path == null) return;
    setState(() => _isAnalyzingDoc = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');

      File file = File(result.files.single.path!);
      String base64File = base64Encode(await file.readAsBytes());
      String extension = result.files.single.extension!.toLowerCase();
      String mimeType =
          (extension == 'pdf') ? "application/pdf" : "image/$extension";

      // 1. Analyze Document via Gemini 2.5 Vision
      final response = await http.post(
        Uri.parse(_geminiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "Extract Name, Blood Pressure, and Blood Sugar from this health report. Provide a 3-sentence summary of health status. Use LaTeX notation."
                },
                {
                  "inlineData": {"mimeType": mimeType, "data": base64File}
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final aiData = json.decode(response.body);
        final String summary = aiData['candidates']?[0]['content']?['parts']?[0]
                ['text'] ??
            "Digitization failed.";

        // 2. Persist Digitized Report to MongoDB
        await http.post(
          Uri.parse('${ApiConfig.lifeLogUrl}/save_vision_report'),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "user_id": userId,
            "filename": result.files.single.name,
            "summary": summary
          }),
        );

        _showSnackBar("Report Analyzed & Synced to LifeLog Hub! ✅");
        _fetchFullHistory();
      }
    } catch (e) {
      _showSnackBar("Connectivity Error: Check Mobile Data/Wi-Fi.",
          isError: true);
    } finally {
      setState(() => _isAnalyzingDoc = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
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
        title: Text("LifeLog Hub",
            style: AppStyles.headingStyle.copyWith(fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 20),
              onPressed: _fetchFullHistory)
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _fetchFullHistory,
                  color: AppColors.primaryTeal,
                  child: _buildTimeline()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAnalyzingDoc ? null : _pickAndAnalyzeDocument,
        backgroundColor: AppColors.primaryTeal,
        icon: _isAnalyzingDoc
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(LucideIcons.fileUp),
        label: Text(_isAnalyzingDoc ? "Analyzing..." : "Upload Report"),
      ),
    );
  }

  Widget _buildTimeline() {
    bool hasData = _dailyMoves.isNotEmpty ||
        _mindEase.isNotEmpty ||
        _appointments.isNotEmpty ||
        _medicines.isNotEmpty ||
        _digitizedReports.isNotEmpty;

    if (!hasData) return _buildEmptyState();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        const Text("Your Holistic History",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const Text("Synced from MongoDB & PostgreSQL",
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 24),
        if (_digitizedReports.isNotEmpty) ...[
          _buildSectionHeader(
              "AI Digitized Records", LucideIcons.fileSearch, Colors.teal),
          ..._digitizedReports.map((report) => _buildVisionCard(report)),
          const SizedBox(height: 24),
        ],
        _buildSectionHeader(
            "Active Schedule", LucideIcons.bellRing, Colors.blue),
        if (_appointments.isEmpty && _medicines.isEmpty)
          _buildSmallPlaceholder()
        else ...[
          ..._appointments
              .map((item) => _buildCareCard(item, "appointment", Colors.blue)),
          ..._medicines.map((item) =>
              _buildCareCard(item, "medicine", AppColors.primaryTeal)),
        ],
        const SizedBox(height: 24),
        _buildSectionHeader(
            "Clinical Assessments", LucideIcons.activity, Colors.orange),
        if (_dailyMoves.isEmpty && _mindEase.isEmpty)
          _buildSmallPlaceholder()
        else ...[
          ..._dailyMoves.map(
              (item) => _buildAssessmentCard(item, Colors.orange, "Fitness")),
          ..._mindEase.map((item) =>
              _buildAssessmentCard(item, Colors.purple, "Mental Health")),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildVisionCard(dynamic report) {
    final String filename = report['inputs']?['filename'] ?? "Medical Scan";
    final String summary = report['result'] ?? "No analysis found.";

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.teal.shade50)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(filename,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal))),
                const Icon(LucideIcons.checkCircle,
                    color: Colors.teal, size: 14),
              ],
            ),
            const SizedBox(height: 10),
            Text(summary,
                style: const TextStyle(
                    fontSize: 13, height: 1.4, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildCareCard(dynamic item, String type, Color color) {
    final String title =
        item['doctor_name'] ?? item['medicine_name'] ?? "Schedule Item";
    final String time = item['time'] ?? "Daily";
    final String date = item['date'] ?? "N/A";

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
            type == "appointment" ? LucideIcons.calendarDays : LucideIcons.pill,
            color: color,
            size: 20),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle:
            Text(type == "appointment" ? "$date at $time" : "Set for $time"),
        trailing:
            const Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey),
        onTap: () async {
          final refresh = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (c) => AppointmentBookScreen(
                      existingData: item, initialMode: type)));
          if (refresh == true) _fetchFullHistory();
        },
      ),
    );
  }

  Widget _buildAssessmentCard(dynamic item, Color themeColor, String label) {
    final String recordId =
        item['_id']?.toString() ?? DateTime.now().toIso8601String();
    final String result = item['result'] ?? "Logged";
    final Map<String, dynamic> inputs = item['inputs'] ?? {};
    final bool isCoachLoading = _tipLoadingState[recordId] ?? false;
    final String? tip = _dynamicTips[recordId];

    String dateStr = "Recent";
    try {
      DateTime dt = DateTime.parse(item['timestamp']);
      dateStr = DateFormat('MMM d - hh:mm a').format(dt.toLocal());
    } catch (_) {}

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: themeColor.withOpacity(0.1))),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: themeColor,
        leading: Icon(
            label == "Fitness" ? LucideIcons.flame : LucideIcons.brain,
            color: themeColor,
            size: 22),
        title: Text(result,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("$label • $dateStr",
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: themeColor.withOpacity(0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("DATA SNAPSHOT",
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                    inputs.entries
                        .map((e) => "${e.key}: ${e.value}")
                        .join(" | "),
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black54)),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("XAI COACHING",
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                            letterSpacing: 1)),
                    if (tip == null && !isCoachLoading)
                      GestureDetector(
                        onTap: () => _generateDynamicInsight(
                            recordId, label, inputs, result),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.sparkles,
                                size: 12, color: Colors.orange),
                            SizedBox(width: 4),
                            Text("Coach Me",
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (isCoachLoading)
                  const LinearProgressIndicator()
                else if (tip != null)
                  Text(tip,
                      style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                          height: 1.5))
                else
                  const Text("Tap 'Coach Me' to analyze this specific session.",
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clipboardList,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("LifeLog timeline is empty.",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            TextButton(
                onPressed: _fetchFullHistory,
                child: const Text("Refresh Status"))
          ],
        ),
      );

  Widget _buildErrorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.cloudOff,
                  size: 48, color: AppColors.errorRed),
              const SizedBox(height: 16),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.errorRed,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: _fetchFullHistory,
                  child: const Text("Try Reconnect")),
            ],
          ),
        ),
      );

  Widget _buildSmallPlaceholder() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text("No entries found in this category.",
            style: TextStyle(
                fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
      );
}
