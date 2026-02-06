import 'package:flutter/material.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final QuizRepository _quizRepo = QuizRepository();
  List<ExamModel> _exams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    final exams = await _quizRepo.getAllExams();
    setState(() {
      _exams = exams;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Dashboard"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _exams.isEmpty
              ? const Center(child: Text("No quizzes created yet."))
              : ListView.builder(
                  itemCount: _exams.length,
                  itemBuilder: (context, index) {
                    final exam = _exams[index];

                    // Teacher sets max marks when creating quiz
                    // For now, derive from exam.totalMarks
                    final maxMarks = exam.totalMarks;

                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text("Difficulty: ${exam.difficulty}"),
                            Text("Created: ${exam.timestamp}"),
                            const SizedBox(height: 12),

                            // ✅ Dynamic marks tab
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${exam.totalMarks}/$maxMarks",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                            Text("Questions: ${exam.questions.length}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
