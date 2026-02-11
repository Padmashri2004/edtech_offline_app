import 'package:flutter/material.dart';
import 'src/features/quiz_exam_gen/presentation/quiz_play_screen.dart';
import 'src/features/quiz_exam_gen/data/models/exam_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EdTech App',
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Dummy exam data just to launch QuizPlayScreen
    final exam = ExamModel(
      id: 1,
      title: "Sample Quiz",
      type: "quiz",
      difficulty: "Easy",
      timerMinutes: 10,
      totalMarks: 10,
      timestamp: DateTime.now().toIso8601String(),
      questions: [
        QuestionModel(
          id: 1,
          questionText: "What is 2 + 2?",
          type: "MCQ",
          options: ["3", "4", "5", "6"],
          correctAnswer: "4",
          marks: 1,
          explanation: "2 + 2 equals 4.",
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizPlayScreen(exam: exam), // ✅ FIXED
              ),
            );
          },
          child: const Text("Start Quiz"),
        ),
      ),
    );
  }
}
