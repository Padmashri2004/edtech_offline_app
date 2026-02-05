import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/pdf_export_service.dart';

class TeacherQuizDashboard extends StatefulWidget {
  const TeacherQuizDashboard({super.key});

  @override
  State<TeacherQuizDashboard> createState() => _TeacherQuizDashboardState();
}

class _TeacherQuizDashboardState extends State<TeacherQuizDashboard> {
  List<ExamModel> _exams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    final repo = context.read<QuizRepository>();
    final list = await repo.getAllExams();
    if (mounted) {
      setState(() {
        _exams = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteExam(int id) async {
    final repo = context.read<QuizRepository>();
    await repo.deleteExam(id);
    _loadExams(); // Refresh list
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Quiz Deleted")));
    }
  }

  Future<void> _exportExam(ExamModel exam) async {
    final messenger = ScaffoldMessenger.of(context);
    final exportService = PdfExportService();

    try {
      final filePath = await exportService.generateExamPdf(exam);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text("Saved: $filePath")));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text("Export failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Dashboard: My Quizzes")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exams.isEmpty
              ? const Center(child: Text("Welcome to Teacher's portal"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _exams.length,
                  itemBuilder: (ctx, i) {
                    final exam = _exams[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(exam.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "Questions: ${exam.questions.length} • Difficulty: ${exam.difficulty}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Export Button
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf,
                                  color: Colors.indigo),
                              tooltip: "Export PDF",
                              onPressed: () => _exportExam(exam),
                            ),
                            // Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: "Delete",
                              onPressed: () => _deleteExam(exam.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("Create New Quiz"),
        icon: const Icon(Icons.add),
        onPressed: () {
          // Navigate to existing creation flow (requires file selection first in your current flow)
          Navigator.pushNamed(context, '/chapter-list');
        },
      ),
    );
  }
}
