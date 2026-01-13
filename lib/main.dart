import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

// Core Imports
import 'package:edtech_offline_app/src/core/database/database_helper.dart';
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';

// Feature Imports
import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/ai_assistant/presentation/ai_chat_controller.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/paper_generation_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/pdf_export_service.dart';
import 'package:edtech_offline_app/src/features/textbook_viewer/presentation/chapter_list_screen.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/quiz_gen_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize On-Device AI Pipeline
  await _initAiEngine();

  // 2. Initialize Core Database
  await DatabaseHelper.instance.database;

  // 3. Setup Dependencies for Member 1
  final aiService = AIService();
  final aiRepository = AIRepository(aiService);
  final quizRepository = QuizRepository();

  // 4. Run App with Provider injection
  runApp(
    MultiProvider(
      providers: [
        // AI Chat Controller
        ChangeNotifierProvider(
          create: (_) => AIChatController(aiRepository),
        ),
        // Repository Providers
        Provider<AIRepository>(create: (_) => aiRepository),
        Provider<QuizRepository>(create: (_) => quizRepository),

        // Domain Services (Module 1, 6 & PDF)
        Provider<PaperGenerationService>(
          create: (_) => PaperGenerationService(
            aiRepository: aiRepository,
            quizRepository: quizRepository,
          ),
        ),
        Provider<PdfExportService>(
          create: (_) => PdfExportService(),
        ),
      ],
      child: const EdTechApp(),
    ),
  );
}

/// Member 1: AI Model Initialization Logic
Future<void> _initAiEngine() async {
  try {
    await FlutterGemma.initialize();
    
    // IMPORTANT: Ensure 'assets/models/gemma.task' exists in your project folder
    await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
    ).fromAsset('assets/models/gemma.task').install();

    debugPrint(" ✅ Member 1: Offline AI Engine Ready");
  } catch (e) {
    debugPrint(" ❌ Member 1: AI Init Error: $e");
  }
}

class EdTechApp extends StatelessWidget {
  const EdTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline EdTech',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      // Define Routes for Navigation
      initialRoute: '/',
      routes: {
        '/': (context) => const RoleSelectionScreen(),
        '/chapter-list': (context) => const ChapterListScreen(),
        '/quiz-gen': (context) => const QuizGenScreen(),
      },
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Offline EdTech Portal")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            const Text(
              "Select Your Role",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            // Teacher Role Button (Lead Member 1 Flow)
            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_outline),
                label: const Text("Continue as Teacher"),
                onPressed: () {
                  // Navigate to Chapter Selection (Module 1 Flow)
                  Navigator.pushNamed(context, '/chapter-list');
                },
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Placeholder Buttons for other roles
            SizedBox(
              width: 250,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.child_care),
                label: const Text("Continue as Student"),
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text("Student Portal: Member 3 Task")),
                   );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}