import 'package:flutter/material.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/exam_repository.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
    with SingleTickerProviderStateMixin {
  final QuizRepository _quizRepo = QuizRepository();
  final ExamRepository _examRepo = ExamRepository();

  List<ExamModel> _quizzes = [];
  List<ExamModel> _exams = [];
  bool _loading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    final quizzes = await _quizRepo.getAllQuizzes();
    final exams = await _examRepo.getAllExams();
    if (!mounted) return;
    setState(() {
      _quizzes = quizzes;
      _exams = exams;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _deleteAssessment(
      BuildContext context, int assessmentId, bool isQuiz) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (isQuiz) {
      await _quizRepo.deleteQuiz(assessmentId);
    } else {
      await _examRepo.deleteExam(assessmentId);
    }

    if (!mounted) return;

    _loadAssessments();
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text("Assessment deleted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teacher Dashboard',
      routes: {
        '/quiz-gen': (context) =>
            QuizGenerationScreen(onSaved: _loadAssessments),
        '/exam-gen': (context) =>
            ExamGenerationScreen(onSaved: _loadAssessments),
      },
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Teacher Dashboard"),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.quiz), text: "Quizzes"),
              Tab(icon: Icon(Icons.description), text: "Exam Papers"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _loading = true);
                _loadAssessments();
              },
              tooltip: "Refresh",
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildQuizTab(),
                  _buildExamTab(),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (_tabController.index == 0) {
              Navigator.pushNamed(context, '/quiz-gen');
            } else {
              Navigator.pushNamed(context, '/exam-gen');
            }
          },
          icon: const Icon(Icons.add),
          label: const Text("New"),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildQuizTab() {
    if (_quizzes.isEmpty) {
      return _buildEmptyState("No quizzes created yet.", '/quiz-gen');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        return _buildAssessmentCard(context, quiz, isQuiz: true);
      },
    );
  }

  Widget _buildExamTab() {
    if (_exams.isEmpty) {
      return _buildEmptyState("No exams created yet.", '/exam-gen');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        return _buildAssessmentCard(context, exam, isQuiz: false);
      },
    );
  }

  Widget _buildEmptyState(String message, String route) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(message,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 10),
          Text("Upload a textbook and generate your first assessment!",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, route),
            icon: const Icon(Icons.add),
            label: const Text("Create Now"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(BuildContext context, ExamModel assessment,
      {required bool isQuiz}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(assessment.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    if (assessment.id != null) {
                      _deleteAssessment(context, assessment.id!, isQuiz);
                    }
                  },
                  tooltip: "Delete",
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Difficulty: ${assessment.difficulty}"),
            Text(_formatDate(assessment.timestamp),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            _buildMarksBadge(assessment),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${assessment.questions.length} Questions",
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text("${assessment.timerMinutes} mins",
                    style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarksBadge(ExamModel assessment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(
            "${assessment.totalMarks} marks",
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
    );
  }
}

/// Quiz Generation Screen
class QuizGenerationScreen extends StatefulWidget {
  final VoidCallback onSaved;
  const QuizGenerationScreen({super.key, required this.onSaved});

  @override
  State<QuizGenerationScreen> createState() => _QuizGenerationScreenState();
}

class _QuizGenerationScreenState extends State<QuizGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _timerController = TextEditingController();
  final _marksController = TextEditingController();
  final _topicsController = TextEditingController();

  final QuizRepository _quizRepo = QuizRepository();

  Future<void> _saveQuiz() async {
    final navigator = Navigator.of(context);

    if (_formKey.currentState!.validate()) {
      final quiz = ExamModel(
        title: _titleController.text,
        difficulty: _difficultyController.text,
        timestamp: DateTime.now().toIso8601String(),
        timerMinutes: int.parse(_timerController.text),
        totalMarks: int.parse(_marksController.text),
        type: "quiz",
        questions: [],
      );

      await _quizRepo.saveQuiz(quiz);

      if (!mounted) return;

      widget.onSaved();
      navigator.pop();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _difficultyController.dispose();
    _timerController.dispose();
    _marksController.dispose();
    _topicsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Quiz")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Quiz Title"),
                validator: (val) => val!.isEmpty ? "Enter a title" : null,
              ),
              TextFormField(
                controller: _difficultyController,
                decoration: const InputDecoration(labelText: "Difficulty"),
                validator: (val) => val!.isEmpty ? "Enter difficulty" : null,
              ),
              TextFormField(
                controller: _timerController,
                decoration: const InputDecoration(labelText: "Timer (minutes)"),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? "Enter timer" : null,
              ),
              TextFormField(
                controller: _marksController,
                decoration: const InputDecoration(labelText: "Total Marks"),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? "Enter marks" : null,
              ),
              TextFormField(
                controller: _topicsController,
                decoration: const InputDecoration(
                    labelText: "Topics (comma separated)"),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveQuiz,
                icon: const Icon(Icons.save),
                label: const Text("Save Quiz"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Exam Generation Screen
class ExamGenerationScreen extends StatefulWidget {
  final VoidCallback onSaved;
  const ExamGenerationScreen({super.key, required this.onSaved});

  @override
  State<ExamGenerationScreen> createState() => _ExamGenerationScreenState();
}

class _ExamGenerationScreenState extends State<ExamGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _timerController = TextEditingController();
  final _marksController = TextEditingController();
  final _topicsController = TextEditingController();

  final ExamRepository _examRepo = ExamRepository();

  Future<void> _saveExam() async {
    final navigator = Navigator.of(context);

    if (_formKey.currentState!.validate()) {
      final exam = ExamModel(
        title: _titleController.text,
        difficulty: _difficultyController.text,
        timestamp: DateTime.now().toIso8601String(),
        timerMinutes: int.parse(_timerController.text),
        totalMarks: int.parse(_marksController.text),
        type: "exam",
        questions: [],
      );

      await _examRepo.saveExam(exam);

      if (!mounted) return;

      widget.onSaved();
      navigator.pop();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _difficultyController.dispose();
    _timerController.dispose();
    _marksController.dispose();
    _topicsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Exam")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Exam Title"),
                validator: (val) => val!.isEmpty ? "Enter a title" : null,
              ),
              TextFormField(
                controller: _difficultyController,
                decoration: const InputDecoration(labelText: "Difficulty"),
                validator: (val) => val!.isEmpty ? "Enter difficulty" : null,
              ),
              TextFormField(
                controller: _timerController,
                decoration: const InputDecoration(labelText: "Timer (minutes)"),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? "Enter timer" : null,
              ),
              TextFormField(
                controller: _marksController,
                decoration: const InputDecoration(labelText: "Total Marks"),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? "Enter marks" : null,
              ),
              TextFormField(
                controller: _topicsController,
                decoration: const InputDecoration(
                    labelText: "Topics (comma separated)"),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveExam,
                icon: const Icon(Icons.save),
                label: const Text("Save Exam"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
