import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_offline_app/services/pdf_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/paper_generation_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/pdf_export_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';

class PaperGenScreen extends StatefulWidget {
  const PaperGenScreen({super.key});
  @override
  State<PaperGenScreen> createState() => _PaperGenScreenState();
}

class _PaperGenScreenState extends State<PaperGenScreen> {
  final PdfService _pdfService = PdfService();
  File? _selectedFile;
  Map<String, dynamic>? _selectedChapter;
  List<Map<String, dynamic>> _chapters = [];
  bool _isProcessing = false;

  List<String> _selectedTopics = [];

  final List<String> _allStudents = [
    "Arun",
    "Bina",
    "Chirag",
    "Deepa",
    "Eshwar",
    "Fatima",
    "Ganesh",
    "Hari"
  ];
  final List<String> _basicStudents = [];
  final List<String> _advancedStudents = [];
  ExamModel? _generatedBasicExam;
  ExamModel? _generatedAdvancedExam;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _selectedFile == null) {
      _selectedFile = args['file'] as File;

      if (args['selection'] != null) {
        String? title = args['title'];
        Map<String, List<String>> selectionMap =
            args['selection'] as Map<String, List<String>>;
        if (title != null && selectionMap.containsKey(title)) {
          _selectedTopics = selectionMap[title]!;
        }
      }
      _loadChaptersFromFile(_selectedFile!);
    }
  }

  Future<void> _loadChaptersFromFile(File file) async {
    final chaps = await _pdfService.getChapters(file);
    if (mounted) {
      setState(() {
        _selectedFile = file;
        _chapters = chaps;

        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args != null && args['title'] != null) {
          try {
            _selectedChapter =
                _chapters.firstWhere((c) => c['title'] == args['title']);
          } catch (e) {
            // Ignore mismatch
          }
        }
      });
    }
  }

  Future<void> _pickTextbook() async {
    final file = await _pdfService.pickTextbook();
    if (file != null) {
      _loadChaptersFromFile(file);
    }
  }

  void _toggleStudent(String name, bool isAdvanced) {
    setState(() {
      if (isAdvanced) {
        if (_advancedStudents.contains(name)) {
          _advancedStudents.remove(name);
        } else {
          _advancedStudents.add(name);
          _basicStudents.remove(name);
        }
      } else {
        if (_basicStudents.contains(name)) {
          _basicStudents.remove(name);
        } else {
          _basicStudents.add(name);
          _advancedStudents.remove(name);
        }
      }
    });
  }

  Future<void> _generatePapers() async {
    // 1. Capture dependencies immediately
    final messenger = ScaffoldMessenger.of(context);
    final genService = context.read<PaperGenerationService>();

    if (_selectedFile == null || _selectedChapter == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text("Please select a textbook and chapter.")));
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final text = await _pdfService.extractChapterText(_selectedFile!,
          _selectedChapter!['startPage'], _selectedChapter!['endPage']);

      final results = await genService.generateDifferentiatedPapers(
        chapterTitle: _selectedChapter!['title'],
        rawContent: text,
        basicStudents: _basicStudents,
        advancedStudents: _advancedStudents,
        focusTopics: _selectedTopics,
      );

      if (!mounted) return;
      setState(() {
        _generatedBasicExam = results['basic'];
        _generatedAdvancedExam = results['advanced'];
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      // Use captured messenger (Safe)
      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _exportPdf(ExamModel exam) async {
    // 1. Capture dependencies immediately
    final messenger = ScaffoldMessenger.of(context);
    final exportService = context.read<PdfExportService>();

    try {
      final file = await exportService.generateExamPdf(exam);
      // Use captured messenger (Safe)
      messenger
          .showSnackBar(SnackBar(content: Text("PDF Saved: ${file.path}")));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Export Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mod 6: Question Paper Gen")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                  _selectedFile?.path.split('/').last ?? "Select Textbook"),
              trailing: ElevatedButton(
                  onPressed: _pickTextbook, child: const Text("Upload")),
            ),
            if (_chapters.isNotEmpty)
              DropdownButton<Map<String, dynamic>>(
                value: _selectedChapter,
                hint: const Text("Select Chapter"),
                isExpanded: true,
                items: _chapters
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c['title'])))
                    .toList(),
                onChanged: (v) => setState(() => _selectedChapter = v),
              ),
            const Divider(),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("Assign Students to Tiers:",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(
              height: 150,
              child: ListView.builder(
                itemCount: _allStudents.length,
                itemBuilder: (ctx, i) {
                  final name = _allStudents[i];
                  return ListTile(
                    title: Text(name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilterChip(
                            label: const Text("Basic"),
                            selected: _basicStudents.contains(name),
                            onSelected: (_) => _toggleStudent(name, false)),
                        const SizedBox(width: 5),
                        FilterChip(
                            label: const Text("Adv"),
                            selected: _advancedStudents.contains(name),
                            onSelected: (_) => _toggleStudent(name, true)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _generatePapers,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white),
                child: const SizedBox(
                    width: double.infinity,
                    child: Center(child: Text("Generate Papers"))),
              ),
            const SizedBox(height: 20),
            if (_generatedBasicExam != null)
              _buildExamCard(_generatedBasicExam!, true),
            if (_generatedAdvancedExam != null)
              _buildExamCard(_generatedAdvancedExam!, false),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(ExamModel exam, bool isBasic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(Icons.description,
            color: isBasic ? Colors.green : Colors.blue),
        title: Text(exam.title),
        subtitle: Text("${exam.questions.length} Questions"),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _openReviewScreen(exam)),
          IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _exportPdf(exam)),
        ]),
      ),
    );
  }

  void _openReviewScreen(ExamModel exam) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: Text("Edit: ${exam.title}")),
        body: StatefulBuilder(builder: (ctx, setInnerState) {
          return ListView.builder(
            itemCount: exam.questions.length,
            itemBuilder: (ctx, i) {
              final q = exam.questions[i];
              return Dismissible(
                key: UniqueKey(),
                onDismissed: (_) =>
                    setInnerState(() => exam.questions.removeAt(i)),
                background: Container(
                    color: Colors.red, child: const Icon(Icons.delete)),
                child: ListTile(
                  title: Text(q.questionText),
                  subtitle: Text(q.correctAnswer),
                  onTap: () => _showEditDialog(ctx, q,
                      (newQ) => setInnerState(() => exam.questions[i] = newQ)),
                ),
              );
            },
          );
        }),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.save),
          onPressed: () async {
            // 1. Capture dependencies Synchronously (BEFORE await)
            final repo = context.read<QuizRepository>();
            final navigator = Navigator.of(context);

            // 2. Perform Async
            if (exam.id != null) await repo.deleteExam(exam.id!);
            await repo.saveExam(exam);

            // 3. Use Captured navigator (Safe)
            navigator.pop();
          },
        ),
      );
    }));
  }

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
                    maxLines: 3),
                const SizedBox(height: 10),
                TextField(
                    controller: TextEditingController(text: ans),
                    onChanged: (v) => ans = v,
                    decoration: const InputDecoration(labelText: "Answer"),
                    maxLines: 2),
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
                          explanation: q.explanation));
                      Navigator.pop(c);
                    },
                    child: const Text("Save")),
              ],
            ));
  }
}
