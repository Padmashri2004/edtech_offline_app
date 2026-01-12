import 'package:flutter/material.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Portal"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: const Center(child: Text("Welcome, Teacher! AI Quiz tools coming soon.")),
    );
  }
}