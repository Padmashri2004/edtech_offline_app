import 'package:flutter/material.dart';
import 'student_quiz_play_screen.dart';

class StudentQuizListScreen extends StatelessWidget {
  const StudentQuizListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizzes = [
      {
        "title": "Science Quiz – Photosynthesis",
        "subject": "Science",
        "marks": "20",
        "time": "30 mins",
        "postedBy": "Mrs. Mary",
      },
      {
        "title": "Math Quiz – Fractions",
        "subject": "Math",
        "marks": "15",
        "time": "20 mins",
        "postedBy": "Mr. John",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Available Quizzes"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          final q = quizzes[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              title: Text(
                q["title"]!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "${q["subject"]} • ${q["marks"]} marks • ${q["time"]}",
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentQuizPlayScreen(
                      quizTitle: q["title"]!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
