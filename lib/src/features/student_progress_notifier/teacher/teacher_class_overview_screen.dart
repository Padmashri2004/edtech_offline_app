import 'package:flutter/material.dart';
import 'teacher_student_profile_screen.dart';

class TeacherClassOverviewScreen extends StatelessWidget {
  const TeacherClassOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final students = ["Anu", "Rahul", "Meera"];

    return Scaffold(
      appBar: AppBar(title: const Text("Class Overview")),
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (_, i) {
          return ListTile(
            title: Text(students[i]),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherStudentProfileScreen(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
