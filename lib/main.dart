import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'package:edtech_offline_app/src/core/database/database_helper.dart';
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';
import 'package:edtech_offline_app/src/core/utils/asset_manager.dart';
import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/paper_generation_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/pdf_export_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/textbook_viewer/presentation/chapter_list_screen.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/quiz_gen_screen.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/paper_gen_screen.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/quiz_play_screen.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/student_quiz_list_screen.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/teacher_quiz_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initAiEngine();
  await DatabaseHelper.instance.database;

  final aiService = AIService();
  final aiRepository = AIRepository(aiService);
  final quizRepository = QuizRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<AIRepository>(create: (_) => aiRepository),
        Provider<QuizRepository>(create: (_) => quizRepository),
        Provider<PaperGenerationService>(
          create: (_) => PaperGenerationService(
            aiRepository: aiRepository,
            quizRepository: quizRepository,
          ),
        ),
        Provider<PdfExportService>(create: (_) => PdfExportService()),
      ],
      child: const EdTechApp(),
    ),
  );
}

Future<void> _initAiEngine() async {
  try {
    await AssetManager.prepareModel();
    await FlutterGemma.initialize();
    debugPrint("✅ AI Engine Ready (Gemma 270M)");
  } catch (e) {
    debugPrint("❌ AI Init Error: $e");
  }
}

class EdTechApp extends StatelessWidget {
  const EdTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline EdTech Portal',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const RoleSelectionScreen(),
        '/teacher-dashboard': (context) => const TeacherQuizDashboard(),
        '/chapter-list': (context) => const ChapterListScreen(),
        '/quiz-gen': (context) => const QuizGenScreen(),
        '/paper-gen': (context) => const PaperGenScreen(),
        '/student-quiz-list': (context) => const StudentQuizListScreen(),
        '/quiz-play': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is ExamModel) {
            return QuizPlayScreen(exam: args);
          }
          return const Scaffold(
              body: Center(child: Text("Error: No Exam Data")));
        },
      },
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offline EdTech Portal"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        // FIXED: Deprecated withOpacity → withValues
                        color: Colors.indigo.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(Icons.school,
                      size: 80, color: Colors.indigo.shade600),
                ),
                const SizedBox(height: 30),
                const Text("Select Your Role",
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo)),
                const SizedBox(height: 10),
                Text("Powered by AI • 100% Offline",
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic)),
                const SizedBox(height: 50),
                _RoleButton(
                  icon: Icons.library_books,
                  label: "Teacher Portal",
                  subtitle: "Create Quizzes & Exam Papers",
                  color: Colors.indigo,
                  isPrimary: true,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/teacher-dashboard'),
                ),
                const SizedBox(height: 20),
                _RoleButton(
                  icon: Icons.child_care,
                  label: "Student Portal",
                  subtitle: "Take Quizzes & View Results",
                  color: Colors.indigo,
                  isPrimary: false,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/student-quiz-list'),
                ),
                const SizedBox(height: 50),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                          icon: Icons.offline_bolt,
                          text: "Works without Internet",
                          color: Colors.green),
                      const SizedBox(height: 12),
                      _InfoRow(
                          icon: Icons.security,
                          text: "100% Privacy • Data stays on device",
                          color: Colors.blue),
                      const SizedBox(height: 12),
                      _InfoRow(
                          icon: Icons.smart_toy,
                          text: "Powered by Gemma 270M AI",
                          color: Colors.orange),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _RoleButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: isPrimary
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 8,
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onPressed,
              child:
                  _ButtonContent(icon: icon, label: label, subtitle: subtitle),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 2),
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onPressed,
              child:
                  _ButtonContent(icon: icon, label: label, subtitle: subtitle),
            ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _ButtonContent(
      {required this.icon, required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 40),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 20),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }
}
