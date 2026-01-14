import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_offline_app/services/pdf_service.dart';
import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';

// Model to hold configuration for a batch of questions
class QuizConfigBatch {
  String type;
  int count;
  String difficulty;
  QuizConfigBatch(
      {this.type = 'MCQ', this.count = 5, this.difficulty = 'Medium'});
}

class QuizGenScreen extends StatefulWidget {
  const QuizGenScreen({super.key});

  @override
  State<QuizGenScreen> createState() => _QuizGenScreenState();
}

class _QuizGenScreenState extends State<QuizGenScreen> {
  final PdfService _pdfService = PdfService();

  String _extractedText = "";
  bool _isExtracting = true;
  bool _isGenerating = false;
  String _chapterTitle = "Untitled Chapter";

  // Mixed Logic: List of configurations
  final List<QuizConfigBatch> _batches = [QuizConfigBatch()];
  final TextEditingController _timerController =
      TextEditingController(text: "30");

  List<QuestionModel> _generatedQuestions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && _extractedText.isEmpty) {
      _chapterTitle = args['title'] ?? "Chapter Content";
      _startExtraction(
        args['file'] as File,
        args['startPage'] as int,
        args['endPage'] as int,
      );
    }
  }

  Future<void> _startExtraction(File file, int start, int end) async {
    try {
      final text = await _pdfService.extractChapterText(file, start, end);
      if (mounted) {
        setState(() {
          _extractedText = text;
          _isExtracting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExtracting = false);
      }
      _showSnack("Error reading PDF: $e");
    }
  }

  Future<void> _handleGenerateMixed() async {
    if (_extractedText.isEmpty) {
      _showSnack("No text to generate from!");
      return;
    }
    setState(() => _isGenerating = true);
    final aiRepo = context.read<AIRepository>();
    List<QuestionModel> allNewQuestions = [];

    try {
      for (var batch in _batches) {
        if (batch.count <= 0) continue;

        final rawData = await aiRepo.getQuizFromChapter(
          rawContent: _extractedText,
          difficulty: batch.difficulty,
          type: batch.type,
          count: batch.count,
        );

        final questions = rawData.map((q) => QuestionModel.fromMap(q)).toList();
        allNewQuestions.addAll(questions);
      }

      if (mounted) {
        setState(() {
          _generatedQuestions = allNewQuestions;
          _isGenerating = false;
        });
        _showSnack("Generated ${allNewQuestions.length} mixed questions.");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
      _showSnack("AI Error: $e");
    }
  }

  void _addManualQuestion() {
    // Reusing the Edit Dialog logic for adding new questions is cleaner,
    // but for now, we'll keep the simple manual add and allow editing later.
    showDialog(
        context: context,
        builder: (context) {
          String qText = "";
          String ans = "";
          return AlertDialog(
            title: const Text("Add Manual Question"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: "Question"),
                  onChanged: (v) => qText = v,
                ),
                TextField(
                  decoration:
                      const InputDecoration(labelText: "Correct Answer"),
                  onChanged: (v) => ans = v,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _generatedQuestions.add(QuestionModel(
                      questionText: qText,
                      correctAnswer: ans,
                      options: [],
                      explanation: "Manually added by teacher.",
                    ));
                  });
                  Navigator.pop(context);
                },
                child: const Text("Add"),
              ),
            ],
          );
        });
  }

  // --- NEW: Edit Dialog Logic (Requirement: Modify questions) ---
  void _showEditDialog(
      BuildContext ctx, QuestionModel q, Function(QuestionModel) onSave) {
    String txt = q.questionText;
    String ans = q.correctAnswer;

    showDialog(
        context: ctx,
        builder: (c) => AlertDialog(
              title: const Text("Edit Question"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: TextEditingController(text: txt),
                  onChanged: (v) => txt = v,
                  decoration: const InputDecoration(labelText: "Question"),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: TextEditingController(text: ans),
                  onChanged: (v) => ans = v,
                  decoration: const InputDecoration(labelText: "Answer"),
                  maxLines: 2,
                ),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    onSave(QuestionModel(
                      id: q.id,
                      examId: q.examId,
                      questionText: txt,
                      correctAnswer: ans,
                      options: q.options,
                      explanation: q.explanation,
                    ));
                    Navigator.pop(c);
                  },
                  child: const Text("Save"),
                ),
              ],
            ));
  }

  Future<void> _saveQuiz() async {
    if (_generatedQuestions.isEmpty) return;

    // --- UPDATED: Capture Timer Value ---
    int timerVal = int.tryParse(_timerController.text) ?? 30;

    final exam = ExamModel(
      title: _chapterTitle,
      difficulty: "Mixed",
      timestamp: DateTime.now().toIso8601String(),
      timerMinutes: timerVal, // Save the timer
      questions: _generatedQuestions,
    );

    final repo = context.read<QuizRepository>();
    int id = await repo.saveExam(exam);

    if (mounted && id != -1) {
      _showSnack("Quiz Saved Successfully! (ID: $id)");
      Navigator.pop(context);
    } else {
      _showSnack("Failed to save quiz.");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _addBatch() {
    setState(() {
      _batches.add(QuizConfigBatch());
    });
  }

  void _removeBatch(int index) {
    if (_batches.length > 1) {
      setState(() {
        _batches.removeAt(index);
      });
    } else {
      _showSnack("At least one question set is required.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_chapterTitle)),
      body: _isExtracting || _isGenerating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    "Generating Quiz...",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    " ⚠️  Please do NOT close the app.",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Config Section
                Expanded(
                  flex: 4,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      const Text(
                        "Configure Quiz Structure",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // Loop through batches
                      for (int i = 0; i < _batches.length; i++)
                        _buildBatchCard(i, _batches[i]),

                      // Add Batch Button
                      OutlinedButton.icon(
                        onPressed: _addBatch,
                        icon: const Icon(Icons.add),
                        label: const Text("Add Another Question Set"),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _timerController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: "Total Timer (mins)",
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text("Generate Mixed Quiz"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                          onPressed: _handleGenerateMixed,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(thickness: 2),

                // Questions Preview Section
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Preview Questions (Tap to Edit)",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: _generatedQuestions.isEmpty
                            ? const Center(
                                child: Text("No questions generated yet."))
                            : ListView.builder(
                                itemCount: _generatedQuestions.length,
                                itemBuilder: (context, index) {
                                  final q = _generatedQuestions[index];
                                  return Dismissible(
                                    key: UniqueKey(),
                                    background: Container(
                                        color: Colors.red,
                                        child: const Icon(Icons.delete,
                                            color: Colors.white)),
                                    onDismissed: (_) {
                                      setState(() {
                                        _generatedQuestions.removeAt(index);
                                      });
                                    },
                                    child: Card(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                            child: Text("${index + 1}")),
                                        title: Text(q.questionText),
                                        subtitle: Text(
                                          "Ans: ${q.correctAnswer}\nType: ${_guessType(q)}",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        isThreeLine: true,
                                        trailing: const Icon(Icons.edit,
                                            size: 16, color: Colors.grey),
                                        // --- NEW: Tap to Edit ---
                                        onTap: () {
                                          _showEditDialog(context, q, (newQ) {
                                            setState(() {
                                              _generatedQuestions[index] = newQ;
                                            });
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _generatedQuestions.isNotEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: "add",
                  onPressed: _addManualQuestion,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: "save",
                  onPressed: _saveQuiz,
                  label: const Text("Save & Finish"),
                  icon: const Icon(Icons.save),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildBatchCard(int idx, QuizConfigBatch batch) {
    return Card(
      key: ObjectKey(batch),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Set ${idx + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _removeBatch(idx),
                  visualDensity: VisualDensity.compact,
                )
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: batch.type,
                    decoration: const InputDecoration(
                        labelText: "Type", border: OutlineInputBorder()),
                    items: ['MCQ', 'Fill-up', 'True/False', 'Short Answer']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => batch.type = v!,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: batch.difficulty,
                    decoration: const InputDecoration(
                        labelText: "Level", border: OutlineInputBorder()),
                    items: ['Easy', 'Medium', 'Hard']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => batch.difficulty = v!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: batch.count.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Number of Questions",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => batch.count = int.tryParse(v) ?? 5,
            ),
          ],
        ),
      ),
    );
  }

  String _guessType(QuestionModel q) {
    if (q.options is List && (q.options as List).isNotEmpty) return "MCQ/T-F";
    return "Fill-up/Short";
  }
}
