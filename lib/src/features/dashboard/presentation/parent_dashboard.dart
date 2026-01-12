import 'package:flutter/material.dart';

// FIX: Ensure this class name is ParentDashboard, not StudentDashboard
class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parent Portal"), backgroundColor: Colors.orange),
      body: const Center(child: Text("Welcome, Parent!")),
    );
  }
}