import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/providers/assessment_provider.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/utils/undo_redo_manager.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/pdf_export_service.dart';

class QuizPreviewScreen extends StatefulWidget {
  const QuizPreviewScreen({super.key});

  @override
  State<QuizPreviewScreen> createState() => _QuizPreviewScreenState();
}

class _QuizPreviewScreenState extends State<QuizPreviewScreen> {
  // ✅ FIXED: Remove generic type parameter
  late UndoRedoManager _undoRedoManager;
  late List<QuestionModel> _questions;
  late ExamModel _quiz;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _undoRedoManager = UndoRedoManager();

    final provider = context.read<AssessmentProvider>();
    _quiz = provider.currentAssessment!;
    _questions = List.from(_quiz.questions);

    _undoRedoManager.saveState(_questions);
  }

  // ✅ FIXED: Pass current state to undo
  void _undo() {
    final previousState = _undoRedoManager.undo(_questions);
    if (previousState != null) {
      setState(() {
        _questions = List.from(previousState);
      });
    }
  }

  // ✅ FIXED: Pass current state to redo
  void _redo() {
    final nextState = _undoRedoManager.redo(_questions);
    if (nextState != null) {
      setState(() {
        _questions = List.from(nextState);
      });
    }
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (ctx) => QuestionEditDialog(
        onSave: (newQuestion) {
          setState(() {
            _undoRedoManager.saveState(_questions);
            _questions.add(newQuestion);
          });
        },
      ),
    );
  }

  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (ctx) => QuestionEditDialog(
        question: _questions[index],
        onSave: (updatedQuestion) {
          setState(() {
            _undoRedoManager.saveState(_questions);
            _questions[index] = updatedQuestion;
          });
        },
      ),
    );
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _undoRedoManager.saveState(_questions);
                _questions.removeAt(index);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _moveQuestion(int from, int to) {
    setState(() {
      _undoRedoManager.saveState(_questions);
      final question = _questions.removeAt(from);
      _questions.insert(to, question);
    });
  }

  Future<void> _saveDraft() async {
    setState(() => _isLoading = true);

    // ✅ FIXED: Explicit type parameter for fold
    final updatedQuiz = _quiz.copyWith(
      questions: _questions,
      totalMarks: _questions.fold<int>(0, (sum, q) => sum + q.marks),
      published: false,
    );

    final provider = context.read<AssessmentProvider>();
    await provider.saveAssessment(updatedQuiz);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Saved as draft')),
      );
    }
  }

  Future<void> _publish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish Quiz?'),
        content: const Text(
          'This will make the quiz visible to all students. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      // ✅ FIXED: Explicit type parameter
      final publishedQuiz = _quiz.copyWith(
        questions: _questions,
        totalMarks: _questions.fold<int>(0, (sum, q) => sum + q.marks),
        published: true,
      );

      final provider = context.read<AssessmentProvider>();
      await provider.saveAssessment(publishedQuiz);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Quiz published to students!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _exportPDF() async {
    setState(() => _isLoading = true);

    final pdfService = context.read<PDFExportService>();

    // ✅ FIXED: Explicit type parameter
    final quizWithUpdatedQuestions = _quiz.copyWith(
      questions: _questions,
      totalMarks: _questions.fold<int>(0, (sum, q) => sum + q.marks),
    );

    final pdfPath = await pdfService.exportExamToPDF(quizWithUpdatedQuestions);

    if (mounted) {
      setState(() => _isLoading = false);

      if (pdfPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📄 PDF saved: ${pdfPath.split('/').last}'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to export PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Explicit type parameter
    final totalMarks = _questions.fold<int>(0, (sum, q) => sum + q.marks);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Preview & Edit'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoRedoManager.canUndo ? _undo : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _undoRedoManager.canRedo ? _redo : null,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPDF,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quiz info card
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _quiz.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoChip(
                        icon: Icons.format_list_numbered,
                        label: '${_questions.length} Questions',
                      ),
                      _InfoChip(
                        icon: Icons.star,
                        label: '$totalMarks Marks',
                      ),
                      _InfoChip(
                        icon: Icons.timer,
                        label: '${_quiz.timerMinutes} min',
                      ),
                      _InfoChip(
                        icon: Icons.school,
                        label: _quiz.difficulty,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Questions list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Questions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Questions list
          Expanded(
            child: _questions.isEmpty
                ? const Center(child: Text('No questions yet. Add some!'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _questions.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex--;
                      _moveQuestion(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final question = _questions[index];
                      return Card(
                        key: ValueKey(question.id ?? index),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(
                            question.questionText,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              '${question.type} • ${question.marks} marks'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editQuestion(index),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteQuestion(index),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (question.options.isNotEmpty) ...[
                                    const Text(
                                      'Options:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    ...question.options
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final letter =
                                          String.fromCharCode(97 + entry.key);
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8, bottom: 4),
                                        child: Text('($letter) ${entry.value}'),
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                  ],
                                  Text(
                                    'Answer: ${question.correctAnswer}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  if (question.explanation.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Explanation: ${question.explanation}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Action buttons
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
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _saveDraft,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Draft'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _publish,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.publish),
                    label: const Text('Publish to Students'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.indigo),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

// Simple Question Edit Dialog
class QuestionEditDialog extends StatefulWidget {
  final QuestionModel? question;
  final Function(QuestionModel) onSave;

  const QuestionEditDialog({
    super.key,
    this.question,
    required this.onSave,
  });

  @override
  State<QuestionEditDialog> createState() => _QuestionEditDialogState();
}

class _QuestionEditDialogState extends State<QuestionEditDialog> {
  late TextEditingController _questionController;
  late TextEditingController _answerController;
  late TextEditingController _explanationController;
  late TextEditingController _marksController;
  late List<TextEditingController> _optionControllers;

  String _selectedType = 'MCQ';
  final List<String> _questionTypes = [
    'MCQ',
    'Fill-up',
    'OddOneOut',
    'True/False',
    'ShortAns',
    'LongAns',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.question != null) {
      _questionController =
          TextEditingController(text: widget.question!.questionText);
      _answerController =
          TextEditingController(text: widget.question!.correctAnswer);
      _explanationController =
          TextEditingController(text: widget.question!.explanation);
      _marksController =
          TextEditingController(text: widget.question!.marks.toString());
      _selectedType = widget.question!.type;

      _optionControllers = widget.question!.options
          .map((opt) => TextEditingController(text: opt))
          .toList();

      while (_optionControllers.length < 4 &&
          (_selectedType == 'MCQ' || _selectedType == 'True/False')) {
        _optionControllers.add(TextEditingController());
      }
    } else {
      _questionController = TextEditingController();
      _answerController = TextEditingController();
      _explanationController = TextEditingController();
      _marksController = TextEditingController(text: '1');
      _optionControllers = List.generate(4, (_) => TextEditingController());
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _explanationController.dispose();
    _marksController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter question text')),
      );
      return;
    }

    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter correct answer')),
      );
      return;
    }

    final marks = int.tryParse(_marksController.text.trim());
    if (marks == null || marks <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid marks')),
      );
      return;
    }

    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final newQuestion = QuestionModel(
      id: widget.question?.id,
      questionText: _questionController.text.trim(),
      type: _selectedType,
      options: options,
      correctAnswer: _answerController.text.trim(),
      marks: marks,
      explanation: _explanationController.text.trim(),
    );

    widget.onSave(newQuestion);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.question == null ? 'Add Question' : 'Edit Question'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Question Type'),
              items: _questionTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                  if (_selectedType == 'MCQ' && _optionControllers.length < 4) {
                    while (_optionControllers.length < 4) {
                      _optionControllers.add(TextEditingController());
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(labelText: 'Question Text'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            if (_selectedType == 'MCQ' || _selectedType == 'True/False') ...[
              const Text('Options:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._optionControllers.asMap().entries.map((entry) {
                final letter = String.fromCharCode(97 + entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(labelText: 'Option ($letter)'),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(labelText: 'Correct Answer'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _marksController,
              decoration: const InputDecoration(labelText: 'Marks'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _explanationController,
              decoration:
                  const InputDecoration(labelText: 'Explanation (Optional)'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
