import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Required for crash resilience
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

class QuizPlayScreen extends StatefulWidget {
  final ExamModel exam;
  const QuizPlayScreen({super.key, required this.exam});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  // State Variables
  int _currentQuestionIndex = 0;
  Map<int, String> _userAnswers = {};
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSubmitted = false;
  int _score = 0;
  bool _isExplaining = false;
  bool _isLoadingState = true; // Wait for SharedPreferences to load

  @override
  void initState() {
    super.initState();
    _restoreState(); // Attempt to restore progress on startup
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- CRASH RESILIENCE LOGIC START ---
  /// Restores answers and timer state from local storage if the app crashed
  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final examId = widget.exam.id ?? 0;

    // 1. Restore Answers
    String? savedAnswers = prefs.getString('quiz_answers_$examId');
    if (savedAnswers != null) {
      try {
        Map<String, dynamic> decoded = jsonDecode(savedAnswers);
        setState(() {
          // Convert String keys back to Int keys
          _userAnswers =
              decoded.map((k, v) => MapEntry(int.parse(k), v.toString()));
        });
      } catch (e) {
        debugPrint("Error parsing saved answers: $e");
      }
    }

    // 2. Restore Timer
    int? targetEpoch = prefs.getInt('quiz_deadline_$examId');
    if (targetEpoch != null) {
      // Resume existing session
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = (targetEpoch - now) ~/ 1000;
      if (diff > 0) {
        _remainingSeconds = diff;
      } else {
        _remainingSeconds = 0; // Time expired while app was closed
      }
    } else {
      // Start new session
      _remainingSeconds =
          (widget.exam.timerMinutes > 0 ? widget.exam.timerMinutes : 30) * 60;
      int newTarget =
          DateTime.now().millisecondsSinceEpoch + (_remainingSeconds * 1000);
      await prefs.setInt('quiz_deadline_$examId', newTarget);
    }

    if (mounted) {
      setState(() => _isLoadingState = false);
    }

    // 3. Decide Flow
    if (_remainingSeconds > 0) {
      _startTimer();
    } else {
      _submitQuiz(); // Auto-submit if time ran out
    }
  }

  /// Saves the current answer to disk immediately
  Future<void> _saveAnswerLocally(int index, String answer) async {
    // Save to memory
    setState(() => _userAnswers[index] = answer);

    // Save to disk
    final prefs = await SharedPreferences.getInstance();
    final examId = widget.exam.id ?? 0;

    // Convert int keys to string for JSON encoding
    Map<String, String> exportMap =
        _userAnswers.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString('quiz_answers_$examId', jsonEncode(exportMap));
  }

  /// Clears local data after successful submission
  Future<void> _clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final examId = widget.exam.id ?? 0;
    await prefs.remove('quiz_answers_$examId');
    await prefs.remove('quiz_deadline_$examId');
  }
  // --- CRASH RESILIENCE LOGIC END ---

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() => _remainingSeconds--);
        }
      } else {
        _submitQuiz();
      }
    });
  }

  void _submitQuiz() {
    _timer?.cancel();
    _clearLocalData(); // Clean up storage

    int correctCount = 0;
    for (int i = 0; i < widget.exam.questions.length; i++) {
      String userAns = _userAnswers[i]?.trim().toLowerCase() ?? "";
      String correctAns =
          widget.exam.questions[i].correctAnswer.trim().toLowerCase();
      if (userAns == correctAns) {
        correctCount++;
      }
    }

    if (mounted) {
      setState(() {
        _isSubmitted = true;
        _score = correctCount;
      });
    }
  }

  // --- AI Logic (Explanation) ---
  Future<void> _explainMistake(QuestionModel question, String userAns) async {
    setState(() => _isExplaining = true);
    final aiService = context.read<AIService>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      String actualUserAns = userAns.isEmpty ? "No Answer" : userAns;
      String explanation = await aiService.explainMistake(
        question: question.questionText,
        studentAns: actualUserAns,
        correctAns: question.correctAnswer,
      );

      if (!mounted) return;
      _showExplanationDialog(explanation);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("AI Error: $e")));
    } finally {
      if (mounted) {
        setState(() => _isExplaining = false);
      }
    }
  }

  void _showExplanationDialog(String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("AI Explanation"),
        content: SingleChildScrollView(child: Text(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  // --- Helper: Parse Options Logic ---
  List<String> _parseOptions(dynamic options) {
    if (options is List) {
      return options.map((e) => e.toString()).toList();
    }
    if (options is String && options.isNotEmpty) {
      return options
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((e) => e.trim())
          .toList();
    }
    return [];
  }

  // --- Helper: Timer Formatter ---
  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // --- UI Builder ---
  @override
  Widget build(BuildContext context) {
    // 1. Loading State
    if (_isLoadingState) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Result State
    if (_isSubmitted) {
      return _buildResultScreen();
    }

    // 3. Quiz State
    final question = widget.exam.questions[_currentQuestionIndex];
    final options = _parseOptions(question.options);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam.title, style: const TextStyle(fontSize: 16)),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: _remainingSeconds < 60
                  ? Colors.red.shade100
                  : Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _remainingSeconds < 60 ? Colors.red : Colors.indigo,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.black87),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _remainingSeconds < 60 ? Colors.red : Colors.indigo,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.exam.questions.length,
            backgroundColor: Colors.grey.shade200,
            color: Colors.indigo,
            minHeight: 6,
          ),

          // Question Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Question ${_currentQuestionIndex + 1}/${widget.exam.questions.length}",
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    question.questionText,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  // Options or TextField
                  if (options.isNotEmpty)
                    ...List.generate(options.length, (index) {
                      String optLabel =
                          String.fromCharCode(65 + index); // A, B, C...
                      bool isSelected =
                          _userAnswers[_currentQuestionIndex] == optLabel;
                      return _buildOptionCard(optLabel, options[index],
                          isSelected, _currentQuestionIndex);
                    })
                  else
                    TextField(
                      controller: TextEditingController(
                          text: _userAnswers[_currentQuestionIndex]),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Type your answer here...",
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      onChanged: (val) =>
                          _saveAnswerLocally(_currentQuestionIndex, val),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: _currentQuestionIndex > 0
                  ? () => setState(() => _currentQuestionIndex--)
                  : null,
              child: const Text("Previous"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_currentQuestionIndex < widget.exam.questions.length - 1) {
                  setState(() => _currentQuestionIndex++);
                } else {
                  _showSubmitDialog();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _currentQuestionIndex == widget.exam.questions.length - 1
                        ? Colors.green
                        : Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _currentQuestionIndex == widget.exam.questions.length - 1
                    ? "Finish"
                    : "Next",
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget: Option Card ---
  Widget _buildOptionCard(
      String label, String text, bool isSelected, int qIndex) {
    return Card(
      color: isSelected ? Colors.indigo.shade50 : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? Colors.indigo : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _saveAnswerLocally(qIndex, label),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? Colors.indigo : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "$label) $text",
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? Colors.indigo.shade900 : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget: Result Screen ---
  Widget _buildResultScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Results"),
        automaticallyImplyLeading: false,
      ),
      body: _isExplaining
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("AI is analyzing your mistake..."),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        "You scored $_score / ${widget.exam.questions.length}",
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Tap on incorrect questions to ask AI for an explanation.",
                        style: TextStyle(
                            color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.exam.questions.length,
                    itemBuilder: (ctx, index) {
                      final question = widget.exam.questions[index];
                      final userAns =
                          _userAnswers[index]?.trim().toLowerCase() ?? "";
                      final correctAns =
                          question.correctAnswer.trim().toLowerCase();
                      final isCorrect = userAns == correctAns;

                      return Card(
                        color: isCorrect
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            question.questionText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Your Answer: ${_userAnswers[index] ?? 'None'}"),
                              Text(
                                "Correct: ${question.correctAnswer}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          trailing: !isCorrect
                              ? IconButton(
                                  icon: const Icon(Icons.psychology,
                                      color: Colors.indigo),
                                  tooltip: "Explain Mistake",
                                  onPressed: () => _explainMistake(
                                    question,
                                    _userAnswers[index] ?? "",
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                      child: const Text("Back to Dashboard"),
                    ),
                  ),
                )
              ],
            ),
    );
  }

  void _showSubmitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Submit Quiz?"),
        content: const Text(
            "Are you sure you want to finish? You cannot change answers after submitting."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitQuiz();
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }
}
