import 'package:flutter/material.dart';
import 'student_adaptive_question_screen.dart';

class StudentDeadlineCheckScreen extends StatelessWidget {
  const StudentDeadlineCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Deadline Check")),
      body: Center(
        child: ElevatedButton(
          child: const Text("Attempt Readiness Question"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StudentAdaptiveQuestionScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
