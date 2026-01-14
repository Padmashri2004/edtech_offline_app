import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

// Core Imports
import 'package:edtech_offline_app/src/core/database/database_helper.dart';
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';
import 'package:edtech_offline_app/src/core/utils/asset_manager.dart'; // Added: For Model Unpacking

// Feature Imports (Member 1 Tasks: AI & Quiz Gen)
import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/paper_generation_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/pdf_export_service.dart';

// Screens (Member 1 UI Flow)
import 'package:edtech_offline_app/src/features/textbook_viewer/presentation/chapter_list_screen.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/quiz_gen_screen.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/paper_gen_screen.dart'; // Added: Module 6 Screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize On-Device AI Pipeline (Member 1 Responsibility)
  await _initAiEngine();

  // 2. Initialize Core Database
  await DatabaseHelper.instance.database;

  // 3. Setup Dependencies
  final aiService = AIService();
  final aiRepository = AIRepository(aiService);
  final quizRepository = QuizRepository();

  // 4. Run App with Provider injection
  runApp(
    MultiProvider(
      providers: [
        // Repository Providers
        Provider<AIRepository>(create: (_) => aiRepository),
        Provider<QuizRepository>(create: (_) => quizRepository),

        // Domain Services (Module 6 & PDF)
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
    // Step A: Ensure model is unpacked to local storage [cite: 333]
    await AssetManager.prepareModel();

    // Step B: Initialize the Gemma Engine
    // This loads the Gemma 2B (or 270M Nano) quantized model
    await FlutterGemma.initialize();

    debugPrint("     ✅      Member 1: Offline AI Engine Ready");
  } catch (e) {
    debugPrint(
        "     ❌      Member 1: AI Init Error (Check assets/models/gemma.task): $e");
  }
}

class EdTechApp extends StatelessWidget {
  const EdTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline EdTech (Member 1)',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      // Define Routes for Navigation
      initialRoute: '/',
      routes: {
        // The Entry Point
        '/': (context) => const RoleSelectionScreen(),

        // Module 1 Flow: Select Chapter -> Generate Quiz
        '/chapter-list': (context) => const ChapterListScreen(),
        '/quiz-gen': (context) => const QuizGenScreen(),

        // Module 6 Flow: Question Paper Generation
        '/paper-gen': (context) => const PaperGenScreen(),
      },
    );
  }
}

/// Simple Entry Screen to route specific roles
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

            // Teacher Role Section (Member 1 Scope)
            const Text("Teacher Modules",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),

            // Button 1: Module 1 (Quiz Gen)
            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.quiz),
                label: const Text("Mod 1: Quiz Generator"),
                onPressed: () {
                  // Navigate to Chapter Selection (Module 1 Flow)
                  Navigator.pushNamed(context, '/chapter-list');
                },
              ),
            ),
            const SizedBox(height: 15),

            // Button 2: Module 6 (Paper Gen)
            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.description),
                label: const Text("Mod 6: Question Paper Gen"),
                onPressed: () {
                  // Navigate to Paper Gen Screen (Module 6 Flow)
                  Navigator.pushNamed(context, '/paper-gen');
                },
              ),
            ),

            const Divider(height: 40, indent: 40, endIndent: 40),

            // Placeholder for other roles
            SizedBox(
              width: 250,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.child_care),
                label: const Text("Continue as Student"),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text("Student Portal: Handed off to Member 3")),
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
