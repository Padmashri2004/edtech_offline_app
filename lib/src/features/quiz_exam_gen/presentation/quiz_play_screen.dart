import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

class QuizPlayScreen extends StatefulWidget {
  final ExamModel exam;

  const QuizPlayScreen({super.key, required this.exam});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, String> _answers = {};
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _showExplanations = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.exam.timerMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _submitQuiz();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectAnswer(String answer) {
    setState(() {
      _answers[_currentQuestionIndex] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.exam.questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }

  void _submitQuiz() {
    _timer?.cancel();

    int score = 0;
    for (int i = 0; i < widget.exam.questions.length; i++) {
      final q = widget.exam.questions[i];
      final userAnswer = _answers[i];
      if (userAnswer != null &&
          userAnswer.toLowerCase() == q.correctAnswer.toLowerCase()) {
        score += q.marks;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Quiz Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              'Your Score: $score / ${widget.exam.totalMarks}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _showExplanations = true;
                _currentQuestionIndex = 0;
              });
            },
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('View Explanations'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Exit Quiz'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.exam.questions[_currentQuestionIndex];
    final selectedAnswer = _answers[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam.title),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.timer),
                const SizedBox(width: 8),
                Text(_formatTime(_remainingSeconds)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.exam.questions.length,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${widget.exam.questions.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.questionText,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Image if present
                  if (question.imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(question.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Options
                  if (question.options.isNotEmpty)
                    RadioGroup<String>(
                      groupValue: selectedAnswer,
                      // ✅ FIXED: Using a permanent function that checks state internally
                      onChanged: (value) {
                        // If showing explanations, do not allow changes
                        if (_showExplanations) return;

                        // Otherwise, update selection
                        if (value != null) {
                          _selectAnswer(value);
                        }
                      },
                      child: Column(
                        children: question.options.map((option) {
                          return RadioListTile<String>(
                            value: option,
                            title: Text(option),
                            activeColor: Colors.indigo,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          );
                        }).toList(),
                      ),
                    ),

                  // AI Explanation (if review mode)
                  if (_showExplanations && question.explanation.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb,
                                  color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                "AI Explanation",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(question.explanation),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Correct Answer: ${question.correctAnswer}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Previous"),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: _currentQuestionIndex > 0 ? 1 : 2,
                  child: ElevatedButton.icon(
                    onPressed: _currentQuestionIndex ==
                            widget.exam.questions.length - 1
                        ? (_showExplanations ? null : _submitQuiz)
                        : _nextQuestion,
                    icon: Icon(_currentQuestionIndex ==
                            widget.exam.questions.length - 1
                        ? Icons.check
                        : Icons.arrow_forward),
                    label: Text(
                      _currentQuestionIndex == widget.exam.questions.length - 1
                          ? "Submit"
                          : "Next",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
