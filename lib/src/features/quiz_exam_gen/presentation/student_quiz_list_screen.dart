import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

class StudentQuizListScreen extends StatefulWidget {
  const StudentQuizListScreen({super.key});

  @override
  State<StudentQuizListScreen> createState() => _StudentQuizListScreenState();
}

class _StudentQuizListScreenState extends State<StudentQuizListScreen> {
  List<ExamModel> _availableQuizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    final repo = context.read<QuizRepository>();
    final quizzes = await repo.getAllQuizzes();

    if (mounted) {
      setState(() {
        // Only show published quizzes (teacher side sets exam.type = "quiz")
        _availableQuizzes = quizzes.where((q) => q.type == "quiz").toList();
        _isLoading = false;
      });
    }
  }

  void _startQuiz(ExamModel exam) {
    Navigator.pushNamed(context, '/quiz-play', arguments: exam);
  }

  String _formatTimer(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return mins > 0 ? "$hours hrs $mins mins" : "$hours hrs";
    }
    return "$mins mins";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Portal: Available Quizzes")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableQuizzes.isEmpty
              ? const Center(child: Text("No quizzes posted by teachers yet."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _availableQuizzes.length,
                  itemBuilder: (ctx, i) {
                    final exam = _availableQuizzes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: const Icon(Icons.assignment,
                              color: Colors.indigo),
                        ),
                        title: Text(
                          exam.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Difficulty: ${exam.difficulty}\n"
                          "${exam.questions.length} Questions • ${_formatTimer(exam.timerMinutes)} • ${exam.totalMarks} marks",
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _startQuiz(exam),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Start"),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
