import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/providers/exam_provider.dart';

class QuizGenScreen extends StatefulWidget {
  const QuizGenScreen({super.key});

  @override
  State<QuizGenScreen> createState() => _QuizGenScreenState();
}

class _QuizGenScreenState extends State<QuizGenScreen> {
  final Logger _logger = Logger();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _topicsController = TextEditingController();
  final TextEditingController _marksController = TextEditingController();
  final TextEditingController _timerController = TextEditingController();
  final TextEditingController _tierController = TextEditingController();

  final List<String> _availableTypes = [
    "MCQ",
    "Fill-up",
    "OddOneOut",
    "True/False",
    "ShortAns",
    "LongAns"
  ];

  final Map<String, Map<String, TextEditingController>> _typeControllers = {};

  @override
  void initState() {
    super.initState();
    for (var type in _availableTypes) {
      _typeControllers[type] = {
        "count": TextEditingController(),
        "marks": TextEditingController(),
      };
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicsController.dispose();
    _marksController.dispose();
    _timerController.dispose();
    _tierController.dispose();
    for (var controllers in _typeControllers.values) {
      controllers["count"]?.dispose();
      controllers["marks"]?.dispose();
    }
    super.dispose();
  }

  Future<void> _generateQuiz(ExamProvider examProvider) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final title = _titleController.text.trim();
    final topics = _topicsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final tier = _tierController.text.trim();
    final marksText = _marksController.text.trim();
    final timerText = _timerController.text.trim();

    if (title.isEmpty ||
        topics.isEmpty ||
        tier.isEmpty ||
        marksText.isEmpty ||
        timerText.isEmpty) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final totalMarks = int.tryParse(marksText);
    final timerMinutes = int.tryParse(timerText);

    if (totalMarks == null ||
        totalMarks <= 0 ||
        timerMinutes == null ||
        timerMinutes <= 0) {
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text("Enter valid positive integers for marks and time")));
      return;
    }

    // Calculate marks from question types
    int calculatedMarks = 0;
    List<Map<String, dynamic>> selectedTypes = [];

    for (var type in _availableTypes) {
      final countText = _typeControllers[type]!["count"]!.text.trim();
      final marksPerQText = _typeControllers[type]!["marks"]!.text.trim();

      if (countText.isNotEmpty && marksPerQText.isNotEmpty) {
        final count = int.tryParse(countText);
        final marksPerQ = int.tryParse(marksPerQText);

        if (count != null && marksPerQ != null && count > 0 && marksPerQ > 0) {
          calculatedMarks += count * marksPerQ;
          selectedTypes.add({
            "type": type,
            "count": count,
            "marks": marksPerQ,
          });
        }
      }
    }

    if (calculatedMarks != totalMarks) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text(
                "Marks mismatch! Expected $totalMarks, got $calculatedMarks")),
      );
      return;
    }

    await examProvider.generateExam(
      title: title,
      difficulty: tier,
      topics: topics,
      timerMinutes: timerMinutes,
      totalMarks: totalMarks,
      types: selectedTypes,
    );

    if (!mounted) return;

    if (examProvider.error != null) {
      _logger.e("Quiz generation failed: ${examProvider.error}");
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(examProvider.error!)),
      );
    } else {
      navigator.pushNamed("/quizPreview");
    }
  }

  @override
  Widget build(BuildContext context) {
    final examProvider = Provider.of<ExamProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Generate Quiz")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Quiz Title")),
            const SizedBox(height: 12),
            TextField(
                controller: _topicsController,
                decoration: const InputDecoration(
                    labelText: "Topics (comma separated)")),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Select Tier"),
              items: const [
                DropdownMenuItem(value: "Easy", child: Text("Easy")),
                DropdownMenuItem(value: "Medium", child: Text("Medium")),
                DropdownMenuItem(value: "Hard", child: Text("Hard")),
              ],
              onChanged: (val) {
                if (val != null) {
                  _tierController.text = val;
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _marksController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Total Marks")),
            const SizedBox(height: 12),
            TextField(
                controller: _timerController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Timer (minutes)")),
            const SizedBox(height: 20),

            // Question type inputs
            ..._availableTypes.map((type) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                            child: TextField(
                                controller: _typeControllers[type]!["count"],
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(labelText: "Count"))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: TextField(
                                controller: _typeControllers[type]!["marks"],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: "Marks per Question"))),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                )),

            ElevatedButton(
              onPressed: examProvider.isLoading
                  ? null
                  : () => _generateQuiz(examProvider),
              child: examProvider.isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Generate Quiz"),
            ),
          ],
        ),
      ),
    );
  }
}
