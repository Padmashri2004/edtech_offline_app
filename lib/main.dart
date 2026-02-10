import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:edtech_offline_app/src/core/database/database_helper.dart';
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';
import 'package:edtech_offline_app/src/core/utils/asset_manager.dart';
import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/assessment_repository.dart'; // FIXED: Use unified repository
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/paper_generation_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/pdf_export_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/providers/assessment_provider.dart'; // FIXED: Use unified provider
import 'package:edtech_offline_app/src/features/textbook_viewer/presentation/chapter_list_screen.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/quiz_gen_screen.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/paper_gen_screen.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/quiz_play_screen.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/student_quiz_list_screen.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/teacher_quiz_dashboard.dart';

// Flag to prevent re-initialization
bool _isAiInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize once
  if (!_isAiInitialized) {
    await _initAiEngine();
    await DatabaseHelper.instance.database;
    _isAiInitialized = true;
  }

  // Initialize services
  final aiService = AIService();
  final aiRepository = AIRepository();
  final assessmentRepository =
      AssessmentRepository(); // FIXED: Use unified repository

  runApp(
    MultiProvider(
      providers: [
        Provider<AIService>(create: (_) => aiService),
        Provider<AIRepository>(create: (_) => aiRepository),
        Provider<AssessmentRepository>(
            create: (_) => assessmentRepository), // FIXED: Single repository
        Provider<PaperGenerationService>(
          create: (_) => PaperGenerationService(aiRepository),
        ),
        Provider<PDFExportService>(create: (_) => PDFExportService()),
        ChangeNotifierProvider<AssessmentProvider>(
          // FIXED: Use unified provider
          create: (_) => AssessmentProvider(),
        ),
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
    // Don't crash - app can still work for non-AI features
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
        '/teacher-dashboard': (context) => const TeacherDashboard(),
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
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: Center(
              child: Text("Route not found: ${settings.name}"),
            ),
          ),
        );
      },
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.blue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "Offline EdTech Portal",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Government School Edition",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 60),
              _RoleCard(
                icon: Icons.person,
                title: "Teacher Portal",
                subtitle: "Create Quizzes & Exam Papers",
                onTap: () => Navigator.pushNamed(context, '/teacher-dashboard'),
              ),
              const SizedBox(height: 20),
              _RoleCard(
                icon: Icons.school,
                title: "Student Portal",
                subtitle: "Take Quizzes & Assessments",
                onTap: () => Navigator.pushNamed(context, '/student-quiz-list'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(icon, size: 48, color: Colors.indigo),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.indigo),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
