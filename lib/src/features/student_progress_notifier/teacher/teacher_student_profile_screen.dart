import 'package:flutter/material.dart';

class TeacherStudentProfileScreen extends StatelessWidget {
  const TeacherStudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Profile"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Name: Aarav", style: TextStyle(fontSize: 16)),
            Text("Quiz Performance: Good"),
            Text("Assignments: 1 Pending"),
            Text("Goals Completion: 70%"),
          ],
        ),
      ),
    );
  }
}
