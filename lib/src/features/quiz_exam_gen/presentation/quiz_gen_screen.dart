import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_offline_app/services/pdf_service.dart';
import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';
// 1. ADDED: Import for Undo/Redo
import 'utils/undo_redo_manager.dart';

class QuizConfigBatch {
  String type;
  int count;
  String difficulty;
  int marks;

  QuizConfigBatch({
    this.type = 'MCQ',
    this.count = 5,
    this.difficulty = 'Medium',
    this.marks = 1,
  });
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
  int _maxMarks = 20;
  List<String> _selectedTopics = [];

  final List<QuizConfigBatch> _batches = [QuizConfigBatch()];
  final TextEditingController _timerController =
      TextEditingController(text: "30");
  final TextEditingController _maxMarksController =
      TextEditingController(text: "20");

  List<QuestionModel> _generatedQuestions = [];

  // 2. ADDED: Undo/Redo Manager
  final UndoRedoManager _undoRedoManager = UndoRedoManager(maxStackSize: 50);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && _extractedText.isEmpty) {
      _chapterTitle = args['title'] ?? "Chapter Content";

      if (args['selection'] != null) {
        var selectionMap = args['selection'];
        if (selectionMap is Map && selectionMap.containsKey(_chapterTitle)) {
          _selectedTopics = List<String>.from(selectionMap[_chapterTitle]);
        }
      }

      _startExtraction(
        args['file'] as File,
        args['startPage'] as int,
        args['endPage'] as int,
      );
    }
  }

  // 3. ADDED: Undo and Redo methods
  void _undo() {
    final previousState = _undoRedoManager.undo(_generatedQuestions);
    if (previousState != null) {
      setState(() {
        _generatedQuestions = previousState;
      });
      _showSnack('↶ Undo');
    } else {
      _showSnack('Nothing to undo');
    }
  }

  void _redo() {
    final nextState = _undoRedoManager.redo(_generatedQuestions);
    if (nextState != null) {
      setState(() {
        _generatedQuestions = nextState;
      });
      _showSnack('↷ Redo');
    } else {
      _showSnack('Nothing to redo');
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
      if (mounted) setState(() => _isExtracting = false);
      _showSnack("Error: $e");
    }
  }

  Future<void> _handleGenerateMixed() async {
    if (_extractedText.isEmpty) {
      _showSnack("No text!");
      return;
    }

    int total = _batches.fold(0, (sum, b) => sum + (b.count * b.marks));
    if (total > _maxMarks) {
      _showSnack("Total ($total) exceeds max ($_maxMarks)!");
      return;
    }

    // 4. MODIFIED: Save state before generating
    if (_generatedQuestions.isNotEmpty) {
      _undoRedoManager.saveState(_generatedQuestions);
    }
    setState(() => _isGenerating = true);

    final aiRepo = context.read<AIRepository>();
    List<QuestionModel> all = [];

    try {
      for (var batch in _batches) {
        if (batch.count <= 0) continue;

        final raw = await aiRepo.getQuizFromChapter(
          rawContent: _extractedText,
          difficulty: batch.difficulty,
          type: batch.type,
          count: batch.count,
          focusTopics: _selectedTopics,
          chapterTitle: _chapterTitle,
        );

        final qs = raw.map((q) {
          return QuestionModel(
            questionText: q['q'] ?? q['question'] ?? "",
            options: List<String>.from(q['o'] ?? q['options'] ?? []),
            correctAnswer: q['a'] ?? q['correct_answer'] ?? "",
            explanation: q['e'] ?? q['explanation'] ?? "",
            marks: batch.marks,
          );
        }).toList();

        all.addAll(qs);
      }

      if (mounted) {
        setState(() {
          _generatedQuestions = all;
          _isGenerating = false;
        });
        _showSnack("Generated ${all.length} questions");
      }
    } catch (e) {
      if (mounted) setState(() => _isGenerating = false);
      _showSnack("Error: $e");
    }
  }

  Future<void> _saveQuiz() async {
    if (_generatedQuestions.isEmpty) {
      _showSnack("No questions!");
      return;
    }

    int total = _generatedQuestions.fold(0, (sum, q) => sum + q.marks);
    if (total > _maxMarks) {
      _showSnack("Total ($total) exceeds max!");
      return;
    }

    final exam = ExamModel(
      title: _chapterTitle,
      difficulty: "Mixed",
      timestamp: DateTime.now().toIso8601String(),
      timerMinutes: int.tryParse(_timerController.text) ?? 30,
      questions: _generatedQuestions,
    );

    final repo = context.read<QuizRepository>();
    int id = await repo.saveExam(exam);

    if (mounted && id != -1) {
      _showSnack("Saved! ($total marks)");
      Navigator.pop(context);
    } else {
      _showSnack("Failed to save");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    int current = _generatedQuestions.fold(0, (sum, q) => sum + q.marks);

    return Scaffold(
      // 5. MODIFIED: AppBar with Undo/Redo buttons
      appBar: AppBar(
        title: Text(_chapterTitle),
        actions: [
          // NEW: Undo button
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoRedoManager.canUndo ? _undo : null,
            tooltip: 'Undo (${_undoRedoManager.undoCount})',
          ),
          // NEW: Redo button
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _undoRedoManager.canRedo ? _redo : null,
            tooltip: 'Redo (${_undoRedoManager.redoCount})',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "Marks: $current/$_maxMarks",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: current > _maxMarks ? Colors.red : Colors.green,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isExtracting || _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Generating...",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("⚠️  Do NOT close the app",
                      style: TextStyle(color: Colors.red)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 4,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      const Text("Configure Quiz",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (_selectedTopics.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text("Topics: ${_selectedTopics.join(', ')}",
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontStyle: FontStyle.italic)),
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _maxMarksController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Max Marks",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.score),
                        ),
                        onChanged: (v) =>
                            setState(() => _maxMarks = int.tryParse(v) ?? 20),
                      ),
                      const SizedBox(height: 16),
                      for (int i = 0; i < _batches.length; i++)
                        _buildBatch(i, _batches[i]),
                      OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _batches.add(QuizConfigBatch())),
                        icon: const Icon(Icons.add),
                        label: const Text("Add Question Set"),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _timerController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Timer (mins)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text("Generate Quiz"),
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
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Preview (Tap to Edit)",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("$current marks",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: current > _maxMarks
                                        ? Colors.red
                                        : Colors.green)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _generatedQuestions.isEmpty
                            ? const Center(child: Text("No questions yet"))
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
                                    // 6. MODIFIED: Save state before dismiss
                                    onDismissed: (_) {
                                      _undoRedoManager
                                          .saveState(_generatedQuestions);
                                      setState(() =>
                                          _generatedQuestions.removeAt(index));
                                    },
                                    child: Card(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                            child: Text("${index + 1}")),
                                        title: Text(q.questionText),
                                        subtitle: Text(
                                            "Ans: ${q.correctAnswer}\nMarks: ${q.marks}",
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        isThreeLine: true,
                                        trailing: const Icon(Icons.edit,
                                            size: 16, color: Colors.grey),
                                        onTap: () => _showEditDialog(
                                          q,
                                          (newQ) => setState(() =>
                                              _generatedQuestions[index] =
                                                  newQ),
                                        ),
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
          ? FloatingActionButton.extended(
              onPressed: _saveQuiz,
              label: const Text("Save"),
              icon: const Icon(Icons.save),
            )
          : null,
    );
  }

  Widget _buildBatch(int idx, QuizConfigBatch b) {
    return Card(
      key: ObjectKey(b),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
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
                  onPressed: () {
                    if (_batches.length > 1) {
                      setState(() => _batches.removeAt(idx));
                    }
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // FIXED: Replaced 'value' with 'initialValue' and added 'key'
                    // to ensure the widget rebuilds if the batch type changes
                    key: ValueKey("type_${b.type}"),
                    initialValue: b.type,
                    decoration: const InputDecoration(
                        labelText: "Type", border: OutlineInputBorder()),
                    items: [
                      'MCQ',
                      'Fill-up',
                      'True/False',
                      'OddOneOut',
                      'Rearrange',
                      'Short Answer'
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => b.type = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // FIXED: Replaced 'value' with 'initialValue' and added 'key'
                    key: ValueKey("diff_${b.difficulty}"),
                    initialValue: b.difficulty,
                    decoration: const InputDecoration(
                        labelText: "Level", border: OutlineInputBorder()),
                    items: ['Easy', 'Medium', 'Hard']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => b.difficulty = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: b.count.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: "Questions",
                        border: OutlineInputBorder(),
                        isDense: true),
                    onChanged: (v) =>
                        setState(() => b.count = int.tryParse(v) ?? 5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: b.marks.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: "Marks/Q",
                        border: OutlineInputBorder(),
                        isDense: true),
                    onChanged: (v) =>
                        setState(() => b.marks = int.tryParse(v) ?? 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Subtotal: ${b.count * b.marks} marks",
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(QuestionModel q, Function(QuestionModel) onSave) {
    String txt = q.questionText;
    String ans = q.correctAnswer;
    int marks = q.marks;

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Edit Question"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              ),
              const SizedBox(height: 10),
              TextField(
                controller: TextEditingController(text: marks.toString()),
                onChanged: (v) => marks = int.tryParse(v) ?? 1,
                decoration: const InputDecoration(labelText: "Marks"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          // 7. MODIFIED: Save state before confirming edit
          ElevatedButton(
            onPressed: () {
              // Save state before editing
              _undoRedoManager.saveState(_generatedQuestions);

              onSave(QuestionModel(
                id: q.id,
                examId: q.examId,
                questionText: txt,
                correctAnswer: ans,
                options: q.options,
                explanation: q.explanation,
                marks: marks,
              ));
              Navigator.pop(c);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // 8. MODIFIED: Clear manager on dispose
  @override
  void dispose() {
    _undoRedoManager.clear();
    _timerController.dispose();
    _maxMarksController.dispose();
    super.dispose();
  }
}
