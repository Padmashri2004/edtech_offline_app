import 'package:flutter/material.dart';
import 'teacher_student_profile_screen.dart';

class TeacherClassOverviewScreen extends StatelessWidget {
  const TeacherClassOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final students = ["Aarav", "Ananya", "Rohan"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Class Overview"),
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(students[i]),
          subtitle: const Text("View performance"),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherStudentProfileScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
