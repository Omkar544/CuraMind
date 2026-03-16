import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../widgets/custom_button.dart';
import '../config/api_config.dart'; // Integrated for physical device connectivity

class MindEaseScreen extends StatefulWidget {
  const MindEaseScreen({super.key});

  @override
  State<MindEaseScreen> createState() => _MindEaseScreenState();
}

class _MindEaseScreenState extends State<MindEaseScreen> {
  final _journalController = TextEditingController();
  bool _isLoading = false;
  int _currentStep = 0; // 0: PHQ-9, 1: GAD-7, 2: Journaling
  int _questionIndex = 0; // Tracks the specific question within a scale

  // PHQ-9 & GAD-7 Scores
  final Map<int, int> _phqAnswers = {};
  final Map<int, int> _gadAnswers = {};

  final List<String> _options = [
    "Not at all",
    "Several days",
    "More than half the days",
    "Nearly every day"
  ];

  final List<String> _phqQuestions = [
    "Little interest or pleasure in doing things?",
    "Feeling down, depressed, or hopeless?",
    "Trouble falling or staying asleep, or sleeping too much?",
    "Feeling tired or having little energy?",
    "Poor appetite or overeating?",
    "Feeling bad about yourself — or that you are a failure?",
    "Trouble concentrating on things?",
    "Moving or speaking so slowly that others noticed?",
    "Thoughts that you would be better off dead?"
  ];

  final List<String> _gadQuestions = [
    "Feeling nervous, anxious or on edge?",
    "Not being able to stop or control worrying?",
    "Worrying too much about different things?",
    "Trouble relaxing?",
    "Being so restless that it is hard to sit still?",
    "Becoming easily annoyed or irritable?",
    "Feeling afraid as if something awful might happen?"
  ];

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  // --- Navigation Logic ---

  void _nextQuestion(int totalQuestions) {
    if (_questionIndex < totalQuestions - 1) {
      setState(() {
        _questionIndex++;
      });
    } else {
      setState(() {
        _currentStep++;
        _questionIndex = 0; // Reset for next module
      });
    }
  }

  void _previousQuestion() {
    if (_questionIndex > 0) {
      setState(() {
        _questionIndex--;
      });
    } else if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _questionIndex = _currentStep == 0
            ? _phqQuestions.length - 1
            : _gadQuestions.length - 1;
      });
    } else {
      // If at the very first question, exit the module
      Navigator.pop(context);
    }
  }

  // --- Backend Integration ---

  Future<void> _submitAssessment() async {
    if (_journalController.text.trim().isEmpty) {
      _showError("Please write a few words in your journal first.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');

      if (userId == null) {
        _showError("Session expired. Please login again.");
        return;
      }

      // Calculate clinical scores based on response indexes (0-3)
      int phqTotal = _phqAnswers.values.fold(0, (sum, val) => sum + val);
      int gadTotal = _gadAnswers.values.fold(0, (sum, val) => sum + val);

      String phqLevel = _getPHQLevel(phqTotal);
      String gadLevel = _getGADLevel(gadTotal);

      // 1. Analyze Sentiment via FastAPI (Gemini/VADER)
      // Uses ApiConfig.mindEaseUrl for dynamic IP handling
      final sentimentResponse = await http.post(
        Uri.parse('${ApiConfig.mindEaseUrl}/analyze_sentiment'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"text": _journalController.text.trim()}),
      );

      String sentimentResult = "Neutral";
      String tip = "Take a deep breath and stay mindful.";
      if (sentimentResponse.statusCode == 200) {
        final sData = json.decode(sentimentResponse.body);
        sentimentResult = sData['mood'];
        tip = sData['suggestion'];
      }

      // 2. Save Integrated Assessment to MongoDB via LifeLog Hub
      final saveResponse = await http
          .post(
            Uri.parse('${ApiConfig.mindEaseUrl}/save_assessment'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              "user_id": userId,
              "phq_score": phqTotal,
              "phq_level": phqLevel,
              "gad_score": gadTotal,
              "gad_level": gadLevel,
              "journal_entry": _journalController.text.trim(),
              "journal_sentiment": sentimentResult,
              "overall_suggestion":
                  "You are currently experiencing $phqLevel and $gadLevel.",
              "journal_tip": tip
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (saveResponse.statusCode == 201 || saveResponse.statusCode == 200) {
        if (mounted) {
          _showSummaryDialog(phqLevel, gadLevel, sentimentResult, tip);
        }
      } else {
        _showError(
            "Sync Error: ${saveResponse.statusCode}. Check backend logs.");
      }
    } catch (e) {
      _showError(
          "Connection Failed. Ensure FastAPI is running on --host 0.0.0.0");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getPHQLevel(int score) {
    if (score <= 4) return "Minimal depression";
    if (score <= 9) return "Mild depression";
    if (score <= 14) return "Moderate depression";
    return "Severe depression";
  }

  String _getGADLevel(int score) {
    if (score <= 4) return "Minimal anxiety";
    if (score <= 9) return "Mild anxiety";
    if (score <= 14) return "Moderate anxiety";
    return "Severe anxiety";
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating));

  void _showSummaryDialog(String phq, String gad, String mood, String tip) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(LucideIcons.checkCircle, color: Colors.green),
            const SizedBox(width: 10),
            Text("AI Sync Complete",
                style: AppStyles.subHeadingStyle.copyWith(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Clinical Analysis:",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade700,
                    fontSize: 12)),
            const SizedBox(height: 8),
            _buildResultRow(LucideIcons.cloudRain, "PHQ-9", phq),
            _buildResultRow(LucideIcons.wind, "GAD-7", gad),
            const Divider(height: 30),
            Text("AI Journal Insights:",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade700,
                    fontSize: 12)),
            const SizedBox(height: 8),
            Text("Mood: $mood",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12)),
              child: Text("Pro-Tip: $tip",
                  style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.primaryTeal,
                      fontSize: 13)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/main_wrapper');
            },
            child: const Text("Return to Dashboard"),
          )
        ],
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontSize: 14)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text("MindEase AI Check-in",
            style: AppStyles.headingStyle.copyWith(fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: _previousQuestion,
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _calculateTotalProgress(),
            backgroundColor: Colors.grey.shade200,
            color: AppColors.primaryTeal,
            minHeight: 6,
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primaryTeal))
                : _buildStepContent(),
          ),
        ],
      ),
    );
  }

  double _calculateTotalProgress() {
    int totalQuestions = _phqQuestions.length + _gadQuestions.length + 1;
    int completedQuestions = 0;
    if (_currentStep == 0) completedQuestions = _questionIndex;
    if (_currentStep == 1)
      completedQuestions = _phqQuestions.length + _questionIndex;
    if (_currentStep == 2)
      completedQuestions = _phqQuestions.length + _gadQuestions.length;
    return (completedQuestions + 1) / totalQuestions;
  }

  Widget _buildStepContent() {
    if (_currentStep == 0)
      return _buildQuestionStep(
          "Step 1: PHQ-9 (Mood)", _phqQuestions, _phqAnswers);
    if (_currentStep == 1)
      return _buildQuestionStep(
          "Step 2: GAD-7 (Anxiety)", _gadQuestions, _gadAnswers);
    return _buildJournaling();
  }

  Widget _buildQuestionStep(
      String title, List<String> questions, Map<int, int> answerMap) {
    String currentQuestion = questions[_questionIndex];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: AppStyles.subHeadingStyle.copyWith(
                      color: AppColors.primaryTeal,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              Text("${_questionIndex + 1}/${questions.length}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 32),
          Text(currentQuestion,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 20, height: 1.3)),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                bool isSelected = answerMap[_questionIndex] == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => answerMap[_questionIndex] = index);
                    Future.delayed(const Duration(milliseconds: 350),
                        () => _nextQuestion(questions.length));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryTeal : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isSelected
                              ? AppColors.primaryTeal
                              : Colors.grey.shade300,
                          width: 1.5),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: AppColors.primaryTeal.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_options[index],
                            style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 15)),
                        if (isSelected)
                          const Icon(LucideIcons.checkCircle2,
                              color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournaling() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
              child: Icon(LucideIcons.penTool,
                  size: 48, color: AppColors.primaryTeal)),
          const SizedBox(height: 16),
          const Center(
              child: Text("Step 3: Reflective Journaling",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          const Center(
              child: Text(
                  "Your words help our AI understand your mental landscape.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13))),
          const SizedBox(height: 32),
          TextField(
            controller: _journalController,
            maxLines: 8,
            decoration: AppStyles.inputDecoration.copyWith(
              hintText: "How are you feeling right now? What's on your mind?",
              fillColor: Colors.white,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
                text: "Sync Assessment to Hub", onPressed: _submitAssessment),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
