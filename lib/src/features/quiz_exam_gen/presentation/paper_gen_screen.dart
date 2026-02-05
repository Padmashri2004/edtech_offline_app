import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_offline_app/services/pdf_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/paper_generation_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/pdf_export_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

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

  final List<String> _allStudents =
      List.generate(10, (i) => "Student ${i + 1}");
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
      _loadChaptersFromFile(_selectedFile!);
    }
  }

  Future<void> _pickTextbook() async {
    final file = await _pdfService.pickTextbook();
    if (file != null) _loadChaptersFromFile(file);
  }

  Future<void> _loadChaptersFromFile(File file) async {
    final chaps = await _pdfService.getChapters(file);
    if (!mounted) return;

    setState(() {
      _selectedFile = file;
      _chapters = chaps;

      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['title'] != null) {
        try {
          _selectedChapter =
              _chapters.firstWhere((c) => c['title'] == args['title']);
        } catch (_) {}
      }
    });
  }

  void _toggleStudent(String name, bool isAdv) {
    setState(() {
      if (isAdv) {
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
    final messenger = ScaffoldMessenger.of(context);
    final genService = context.read<PaperGenerationService>();

    if (_selectedFile == null || _selectedChapter == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Select textbook & chapter!")));
      return;
    }

    if (_basicStudents.isEmpty && _advancedStudents.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Assign at least one student")));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      int start = _selectedChapter!['startPage'];
      int end = _selectedChapter!['endPage'];

      final text =
          await _pdfService.extractChapterText(_selectedFile!, start, end);
      final images =
          await _pdfService.extractChapterImages(_selectedFile!, start, end);

      final results = await genService.generateDifferentiatedPapers(
        chapterTitle: _selectedChapter!['title'],
        rawContent: text,
        basicStudents: _basicStudents,
        advancedStudents: _advancedStudents,
        extractedImages: images,
      );

      if (!mounted) return;

      setState(() {
        _generatedBasicExam = results['basic'];
        _generatedAdvancedExam = results['advanced'];
        _isProcessing = false;
      });

      messenger
          .showSnackBar(const SnackBar(content: Text("Papers Generated!")));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _exportPdf(ExamModel exam) async {
    final messenger = ScaffoldMessenger.of(context);
    final exportService = context.read<PdfExportService>();

    try {
      final filePath = await exportService.generateExamPdf(exam);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text("Saved: $filePath")));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mod 6: QP Generator")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_selectedFile?.path.split('/').last ?? "No Textbook"),
              trailing: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload"),
                onPressed: _pickTextbook,
              ),
            ),
            if (_chapters.isNotEmpty)
              DropdownButtonFormField<Map<String, dynamic>>(
                // FIXED: Use initialValue instead of value to fix deprecation warning.
                // The ValueKey ensures the widget rebuilds when selection changes.
                key: ValueKey(_selectedChapter),
                initialValue: _selectedChapter,
                decoration: const InputDecoration(
                    labelText: "Select Chapter", border: OutlineInputBorder()),
                isExpanded: true,
                items: _chapters
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c['title'])))
                    .toList(),
                onChanged: (v) => setState(() => _selectedChapter = v),
              ),
            const Divider(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Assign Tiers (Basic / Advanced)",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _allStudents.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final name = _allStudents[index];
                  bool isBasic = _basicStudents.contains(name);
                  bool isAdv = _advancedStudents.contains(name);

                  return ListTile(
                    dense: true,
                    title: Text(name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilterChip(
                          label: const Text("Basic"),
                          selected: isBasic,
                          selectedColor: Colors.green.shade100,
                          onSelected: (_) => _toggleStudent(name, false),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text("Adv"),
                          selected: isAdv,
                          selectedColor: Colors.blue.shade100,
                          onSelected: (_) => _toggleStudent(name, true),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            if (_isProcessing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Scanning & Generating... Please Wait"),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generatePapers,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text("Generate Papers"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            if (_generatedBasicExam != null ||
                _generatedAdvancedExam != null) ...[
              const SizedBox(height: 20),
              const Text("Generated Papers:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (_generatedBasicExam != null)
                _ExamCard(
                    exam: _generatedBasicExam!,
                    isBasic: true,
                    onDownload: () => _exportPdf(_generatedBasicExam!)),
              if (_generatedAdvancedExam != null)
                _ExamCard(
                    exam: _generatedAdvancedExam!,
                    isBasic: false,
                    onDownload: () => _exportPdf(_generatedAdvancedExam!)),
            ]
          ],
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  final bool isBasic;
  final VoidCallback onDownload;

  const _ExamCard(
      {required this.exam, required this.isBasic, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isBasic ? Colors.green.shade50 : Colors.blue.shade50,
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: Icon(Icons.description,
            color: isBasic ? Colors.green : Colors.blue),
        title: Text(exam.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            "Marks: ${exam.totalMarks} | Students: ${exam.assignedStudents.length}"),
        trailing: IconButton(
          icon: const Icon(Icons.download_for_offline),
          onPressed: onDownload,
          tooltip: "Export PDF",
        ),
      ),
    );
  }
}
