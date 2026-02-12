import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemma/flutter_gemma.dart'; // ✅ Added this import

// Providers
import 'src/features/quiz_exam_gen/presentation/providers/assessment_provider.dart';

// Services
import 'src/features/quiz_exam_gen/domain/pdf_export_service.dart';
// REMOVED: import 'src/core/utils/asset_manager.dart'; (Redundant)

// Screens
import 'src/features/quiz_exam_gen/presentation/teacher_quiz_dashboard.dart';
import 'src/features/textbook_viewer/presentation/class_subject_selection_screen.dart';
import 'src/features/textbook_viewer/presentation/chapter_list_screen.dart';
import 'src/features/quiz_exam_gen/presentation/quiz_gen_screen.dart';
import 'src/features/quiz_exam_gen/presentation/paper_gen_screen.dart';
import 'src/features/quiz_exam_gen/presentation/quiz_preview_screen.dart';
import 'src/features/quiz_exam_gen/presentation/exam_preview_screen.dart';
import 'src/features/quiz_exam_gen/presentation/history_screen.dart';
import 'src/features/quiz_exam_gen/presentation/student_quiz_list_screen.dart';
import 'src/features/quiz_exam_gen/presentation/quiz_play_screen.dart';

// Models
import 'src/features/quiz_exam_gen/data/models/exam_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize the AI Engine
  try {
    await FlutterGemma.initialize();
    debugPrint('✅ FlutterGemma initialized successfully');
  } catch (e) {
    debugPrint('❌ FlutterGemma initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AssessmentProvider()),
        Provider(create: (_) => PDFExportService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RootEd - Offline EdTech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: '/teacher-dashboard',
      routes: {
        '/teacher-dashboard': (context) => const TeacherDashboard(),
        '/class-subject-selection': (context) =>
            const ClassSubjectSelectionScreen(),
        '/quiz-gen': (context) => const QuizGenScreen(),
        '/paper-gen': (context) => const PaperGenScreen(),
        '/quiz-preview': (context) => const QuizPreviewScreen(),
        '/exam-preview': (context) => const ExamPreviewScreen(),
        '/history': (context) => const HistoryScreen(),
        '/student-quiz-list': (context) => const StudentQuizListScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/quiz-play') {
          final exam = settings.arguments as ExamModel;
          return MaterialPageRoute(
            builder: (context) => QuizPlayScreen(exam: exam),
          );
        }
        if (settings.name == '/chapter-list') {
          final metadata = settings.arguments as Map<String, String>?;
          return MaterialPageRoute(
            builder: (context) => ChapterListScreen(metadata: metadata),
          );
        }
        return null;
      },
    );
  }
}
