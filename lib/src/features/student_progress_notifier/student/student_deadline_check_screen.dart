import 'package:flutter/material.dart';
import 'student_adaptive_question_screen.dart';

class StudentDeadlineCheckScreen extends StatelessWidget {
  const StudentDeadlineCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool deadlineNear = true; // dummy logic

    return Scaffold(
      appBar: AppBar(
        title: const Text("Deadline Status"),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: deadlineNear
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Deadline is approaching!",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentAdaptiveQuestionScreen(),
                        ),
                      );
                    },
                    child: const Text("Answer Practice Question"),
                  ),
                ],
              )
            : const Text("You're on track 👍"),
      ),
    );
  }
}
