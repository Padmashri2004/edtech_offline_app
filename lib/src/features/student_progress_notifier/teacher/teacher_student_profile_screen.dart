import 'package:flutter/material.dart';

class TeacherStudentProfileScreen extends StatelessWidget {
  const TeacherStudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Profile")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(title: Text("Quiz Performance: Good")),
            ListTile(title: Text("Assignments: Mostly On Time")),
            ListTile(title: Text("Goals: Actively Working")),
          ],
        ),
      ),
    );
  }
}
