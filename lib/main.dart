import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

//import 'package:provider/provider.dart';
//import 'package:flutter_gemma/flutter_gemma.dart';

// Core Imports
import 'package:edtech_offline_app/src/core/database/database_helper.dart';
//import 'package:edtech_offline_app/src/core/ai/ai_service.dart';
//import 'package:edtech_offline_app/src/core/utils/asset_manager.dart';

// Feature Imports
// import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
// import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';
// import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/paper_generation_service.dart';
// import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/pdf_export_service.dart';
// import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

// Screens
// import 'package:edtech_offline_app/src/features/textbook_viewer/presentation/chapter_list_screen.dart';
// import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/quiz_gen_screen.dart';
// import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/paper_gen_screen.dart';
// import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/quiz_play_screen.dart';
// import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/student_quiz_list_screen.dart';
// import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/teacher_quiz_dashboard.dart'; // NEW IMPORT

//testing UI
import 'package:edtech_offline_app/src/features/student_progress_notifier/student/student_progress_dashboard.dart';
// import 'package:edtech_offline_app/src/features/student_progress_notifier/teacher/teacher_progress_dashboard.dart';
// import 'package:edtech_offline_app/src/features/alumni_connect/alumni_dashboard.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ REQUIRED for Windows / desktop SQLite
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await DatabaseHelper.instance.database;

  runApp(const EdTechApp());
}

    
  // final aiService = AIService();
  // final aiRepository = AIRepository(aiService);
  // final quizRepository = QuizRepository();

    // MultiProvider(
    //   providers: [
        // Provider<AIRepository>(create: (_) => aiRepository),
        // Provider<QuizRepository>(create: (_) => quizRepository),
        // Provider<PaperGenerationService>(
        //   create: (_) => PaperGenerationService(
        //     aiRepository: aiRepository,
        //     quizRepository: quizRepository,
        //   ),
        // ),
        // Provider<PdfExportService>(create: (_) => PdfExportService()),
  //     ],
  //     child: const EdTechApp(),
  //   ),
  // );


// Future<void> _initAiEngine() async {
//   try {
//     await AssetManager.prepareModel();
//    // await FlutterGemma.initialize();
//     debugPrint("  ✅  Member 1: Offline AI Engine Ready");
//   } catch (e) {
//     debugPrint("  ❌  Member 1: AI Init Error: $e");
//   }
// }

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
      initialRoute: '/',
      routes: {
        // '/': (context) => const RoleSelectionScreen(),
        '/': (context) => const StudentProgressDashboard(),

        // '/teacher-dashboard': (context) =>
            // const TeacherQuizDashboard(), // NEW ROUTE
        // '/chapter-list': (context) => const ChapterListScreen(),
        // '/quiz-gen': (context) => const QuizGenScreen(),
        // '/paper-gen': (context) => const PaperGenScreen(),
        // '/student-quiz-list': (context) => const StudentQuizListScreen(),
        // '/quiz-play': (context) {
        //   final args = ModalRoute.of(context)!.settings.arguments;
        //   if (args is ExamModel) {
        //     return QuizPlayScreen(exam: args);
        //   }
        //   return const Scaffold(
        //       body: Center(child: Text("Error: No Exam Data")));
        // },
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

            // TEACHER BUTTON
            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.library_books),
                label: const Text("Teacher (Modules 1 & 6)"),
                onPressed: () {
                  // Navigate to Dashboard instead of directly to Chapter List
                  Navigator.pushNamed(context, '/teacher-dashboard');
                },
              ),
            ),
            const SizedBox(height: 20),

            // STUDENT BUTTON
            SizedBox(
              width: 250,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.child_care),
                label: const Text("Student (Take Quiz)"),
                onPressed: () {
                  Navigator.pushNamed(context, '/student-quiz-list');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
