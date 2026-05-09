import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../widgets/custom_button.dart';
import '../config/api_config.dart';

class MindEaseScreen extends StatefulWidget {
  const MindEaseScreen({super.key});

  @override
  State<MindEaseScreen> createState() => _MindEaseScreenState();
}

class _MindEaseScreenState extends State<MindEaseScreen> {
  final _journalController = TextEditingController();

  bool _isLoading = false;
  int _currentStep = 0;
  int _questionIndex = 0;

  final Map<int, int> _phqAnswers = {};
  final Map<int, int> _gadAnswers = {};

  Map<String, dynamic>? _resultData;

  final List<String> _options = [
    "Not at all",
    "Several days",
    "More than half the days",
    "Nearly every day"
  ];

  final List<String> _phqQuestions = [
    "Little interest or pleasure in doing things?",
    "Feeling down, depressed, or hopeless?",
    "Trouble falling or staying asleep?",
    "Feeling tired or having little energy?",
    "Poor appetite or overeating?",
    "Feeling bad about yourself?",
    "Trouble concentrating on things?",
    "Moving or speaking slowly?",
    "Thoughts that you would be better off dead?"
  ];

  final List<String> _gadQuestions = [
    "Feeling nervous, anxious or on edge?",
    "Not being able to stop worrying?",
    "Worrying too much about things?",
    "Trouble relaxing?",
    "Being so restless it is hard to sit still?",
    "Becoming easily annoyed?",
    "Feeling afraid something awful might happen?"
  ];

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  int _calculateScore(Map<int, int> answers) {
    return answers.values.fold(0, (sum, value) => sum + value);
  }

  String _getPhqLevel(int score) {
    if (score <= 4) return "Minimal depression";
    if (score <= 9) return "Mild depression";
    if (score <= 14) return "Moderate depression";
    if (score <= 19) return "Moderately severe depression";
    return "Severe depression";
  }

  String _getGadLevel(int score) {
    if (score <= 4) return "Minimal anxiety";
    if (score <= 9) return "Mild anxiety";
    if (score <= 14) return "Moderate anxiety";
    return "Severe anxiety";
  }

  void _previousQuestion() {
    if (_questionIndex > 0) {
      setState(() => _questionIndex--);
    } else if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _questionIndex = _currentStep == 0
            ? _phqQuestions.length - 1
            : _gadQuestions.length - 1;
      });
    }
  }

  void _nextQuestion(int totalQuestions) {
    if (_questionIndex < totalQuestions - 1) {
      setState(() => _questionIndex++);
    } else {
      setState(() {
        _currentStep++;
        _questionIndex = 0;
      });
    }
  }

  Future<void> _submitAssessment({bool skipJournal = false}) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      final phqScore = _calculateScore(_phqAnswers);
      final gadScore = _calculateScore(_gadAnswers);

      final phqLevel = _getPhqLevel(phqScore);
      final gadLevel = _getGadLevel(gadScore);

      String journalSentiment = "Not Provided";
      String journalTip = "Keep monitoring your mental health regularly.";

      if (!skipJournal && _journalController.text.trim().isNotEmpty) {
        final sentimentResponse = await http.post(
          Uri.parse('${ApiConfig.mindEaseUrl}/analyze_sentiment'),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "text": _journalController.text.trim(),
          }),
        );

        final sentimentData = json.decode(sentimentResponse.body);

        journalSentiment = sentimentData["mood"];
        journalTip = sentimentData["suggestion"];
      }

      setState(() {
        _resultData = {
          "phq_score": phqScore,
          "phq_level": phqLevel,
          "gad_score": gadScore,
          "gad_level": gadLevel,
          "journal_sentiment": journalSentiment,
          "overall_suggestion": journalTip
        };
      });

      await http.post(
        Uri.parse('${ApiConfig.mindEaseUrl}/save_assessment'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": userId ?? "",
          "phq_score": phqScore,
          "phq_level": phqLevel,
          "gad_score": gadScore,
          "gad_level": gadLevel,
          "journal_entry": skipJournal ? "" : _journalController.text.trim(),
          "journal_sentiment": journalSentiment,
          "overall_suggestion": journalTip,
          "journal_tip": journalTip // ✅ FIXED 422 ERROR
        }),
      );
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MindEase Daily Assessment"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _resultData != null
              ? _buildResult()
              : _buildStep(),
    );
  }

  Widget _buildResult() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Assessment Result", style: AppStyles.headingStyle),
          const SizedBox(height: 20),
          _resultCard("PHQ-9 Score",
              "${_resultData!['phq_score']} (${_resultData!['phq_level']})"),
          _resultCard("GAD-7 Score",
              "${_resultData!['gad_score']} (${_resultData!['gad_level']})"),
          _resultCard("Journal Mood", _resultData!['journal_sentiment']),
          _resultCard("Suggestion", _resultData!['overall_suggestion']),
          const Spacer(),
          CustomButton(
            text: "Go to Home",
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/main_wrapper'),
          )
        ],
      ),
    );
  }

  Widget _resultCard(String title, String value) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value)
        ]),
      ),
    );
  }

  Widget _buildStep() {
    if (_currentStep == 0) {
      return _buildQuestionStep("PHQ-9 (Mood)", _phqQuestions, _phqAnswers);
    }
    if (_currentStep == 1) {
      return _buildQuestionStep("GAD-7 (Anxiety)", _gadQuestions, _gadAnswers);
    }
    return _buildJournal();
  }

  Widget _buildQuestionStep(
      String title, List<String> questions, Map<int, int> answerMap) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.subHeadingStyle),
          const SizedBox(height: 20),
          Text(
            questions[_questionIndex],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _options.length,
              itemBuilder: (context, index) {
                bool isSelected = answerMap[_questionIndex] == index;

                return GestureDetector(
                  onTap: () =>
                      setState(() => answerMap[_questionIndex] = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryTeal : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _options[index],
                      style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousQuestion,
                  child: const Text("Previous"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: answerMap[_questionIndex] == null
                      ? null
                      : () => _nextQuestion(questions.length),
                  child: const Text("Next"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildJournal() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text("Daily Reflection (Optional)", style: AppStyles.subHeadingStyle),
          const SizedBox(height: 12),
          TextField(
            controller: _journalController,
            maxLines: 5,
            decoration: AppStyles.inputDecoration
                .copyWith(hintText: "Write your thoughts (optional)..."),
          ),
          const SizedBox(height: 20),
          CustomButton(
              text: "Submit Assessment", onPressed: () => _submitAssessment()),
          const SizedBox(height: 10),
          TextButton(
              onPressed: () => _submitAssessment(skipJournal: true),
              child: const Text("Skip Journal"))
        ],
      ),
    );
  }
}
