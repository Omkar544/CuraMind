// ✅ COMPLETE PROFESSIONAL LIFELOG HUB (FINAL CARECLOCK FIXED)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../config/api_config.dart';

class LifelogScreen extends StatefulWidget {
  const LifelogScreen({super.key});

  @override
  State<LifelogScreen> createState() => _LifelogScreenState();
}

class _LifelogScreenState extends State<LifelogScreen> {
  List appointments = [];
  List medicines = [];
  List dailyMoves = [];
  List mindEase = [];
  List reports = [];

  bool _isLoading = true;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _fetchAllHistory();
  }

  // =========================
  // SAFE TIME FORMATTER
  // =========================
  String formatIndianTime(String? timestamp) {
    try {
      if (timestamp == null || timestamp.isEmpty) return "Recent";

      // If already formatted IST string (backend formatted)
      if (timestamp.contains("IST")) {
        return timestamp;
      }

      // If ISO (UTC) convert to local
      DateTime parsed = DateTime.parse(timestamp).toLocal();
      return DateFormat('dd MMM yyyy • hh:mm a').format(parsed);
    } catch (_) {
      return timestamp ?? "Recent";
    }
  }

  // =========================
  // FETCH HISTORY
  // =========================
  Future<void> _fetchAllHistory() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    final response = await http.get(
      Uri.parse('${ApiConfig.lifeLogUrl}/history/$userId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        appointments = data['appointments'] ?? [];
        medicines = data['medicines'] ?? [];
        dailyMoves = data['daily_moves'] ?? [];
        mindEase = data['mind_ease'] ?? [];
        reports = data['digitized_reports'] ?? [];
        _isLoading = false;
      });
    }
  }

  // =========================
  // UPLOAD DOCUMENT
  // =========================
  Future<void> _analyzeDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null) return;

    setState(() => _isAnalyzing = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    File file = File(result.files.single.path!);

    var request = http.MultipartRequest(
      "POST",
      Uri.parse('${ApiConfig.lifeLogUrl}/summarize_document'),
    );

    request.fields['user_id'] = userId!;
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    await request.send();
    await _fetchAllHistory();

    setState(() => _isAnalyzing = false);
  }

  // =========================
  // CARD UI
  // =========================
  Widget buildCard({
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Text(time,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const Divider(height: 20),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 14, height: 1.6, color: Colors.grey.shade900)),
        ],
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("LifeLog Hub"),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ================= CARECLOCK =================
                const Text("CareClock",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53935))),
                const SizedBox(height: 10),

                Text("Appointments (${appointments.length})",
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                ...appointments.map((a) => buildCard(
                      title: "Dr. ${a['doctor_name'] ?? ''}",
                      subtitle:
                          "Specialty: ${a['specialty'] ?? ''}\n📅 ${a['date'] ?? ''}\n⏰ ${a['time'] ?? ''}",
                      // ✅ FIXED HERE
                      time: a['timestamp'] ?? "Recent",
                      color: const Color(0xFFE53935),
                    )),

                const SizedBox(height: 20),

                Text("Medicines (${medicines.length})",
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                ...medicines.map((m) => buildCard(
                      title: m['medicine_name'] ?? '',
                      subtitle:
                          "Dosage: ${m['dosage'] ?? ''}\n⏰ ${m['time'] ?? ''}",
                      // ✅ FIXED HERE
                      time: m['timestamp'] ?? "Recent",
                      color: const Color(0xFFE53935),
                    )),

                const SizedBox(height: 30),

                // ================= DAILY MOVES =================
                const Text("DailyMoves",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32))),
                const SizedBox(height: 10),

                ...dailyMoves.map((d) {
                  String result = d['result'] ?? '';
                  Map inputs = d['inputs'] ?? {};

                  Color cardColor = const Color(0xFF2E7D32);
                  String emoji = "💪";

                  if (result.toLowerCase().contains("attention")) {
                    cardColor = Colors.red;
                    emoji = "⚠️";
                  } else if (result.toLowerCase().contains("moderate")) {
                    cardColor = Colors.orange;
                    emoji = "🔥";
                  } else if (result.toLowerCase().contains("optimal")) {
                    cardColor = Colors.green;
                    emoji = "🏆";
                  }

                  return buildCard(
                    title: "$emoji  $result",
                    subtitle:
                        "Steps: ${inputs['steps'] ?? 0}\nCalories: ${inputs['calories'] ?? 0}\nBMI: ${inputs['bmi'] ?? '—'}",
                    time: d['timestamp'] ?? "Recent",
                    color: cardColor,
                  );
                }),

                const SizedBox(height: 20),

                // ================= MINDEASE =================
                const Text("MindEase",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8E24AA))),
                const SizedBox(height: 10),

                ...mindEase.map((m) => buildCard(
                      title: m['result'] ?? '',
                      subtitle: m['inputs']?['journal_entry'] ?? '',
                      time: m['timestamp'] ?? "Recent",
                      color: const Color(0xFF8E24AA),
                    )),

                const SizedBox(height: 30),

                // ================= REPORTS =================
                const Text("Analyzed Reports",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5))),
                const SizedBox(height: 10),

                ...reports.map((r) => buildCard(
                      title: r['inputs']?['filename'] ?? 'Medical Report',
                      subtitle: r['result'] ?? '',
                      time: r['timestamp'] ?? "Recent",
                      color: const Color(0xFF1E88E5),
                    )),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E88E5),
        onPressed: _isAnalyzing ? null : _analyzeDocument,
        label: Text(_isAnalyzing ? "Analyzing..." : "Upload Report"),
        icon: const Icon(Icons.upload_file),
      ),
    );
  }
}