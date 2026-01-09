import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'src/core/database/database_helper.dart'; 
import 'src/core/ai/ai_service.dart'; // Import is now used below

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize On-Device Al Pipeline [cite: 104, 115]
  await FlutterGemma.initialize();

  // 2. Initialize Core Database [cite: 110, 112]
  await DatabaseHelper.instance.database;

  // 3. Alumni & Agentic Transition Logic [cite: 96, 128]
  final ai = AIService();
  await checkAlumniTransitions(ai);

  runApp(const EdTechApp());
}

/// Handles graduation logic for Grades 1-8 in June 
Future<void> checkAlumniTransitions(AIService ai) async {
  final now = DateTime.now();
  if (now.month == 6) {
    // Agentic AI can verify graduation readiness [cite: 128]
    await ai.evaluateProgress("End of year student status check.");
    // Database logic to increment class_id and revoke Class 8 access [cite: 96]
  }
}

class EdTechApp extends StatelessWidget {
  const EdTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Offline EdTech Portal")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Select Your Role to Login", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 30),
            _roleBtn(context, "Teacher", Icons.school),
            _roleBtn(context, "Student", Icons.person),
            _roleBtn(context, "Parent", Icons.family_restroom),
          ],
        ),
      ),
    );
  }

  Widget _roleBtn(BuildContext context, String role, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text("Continue as $role"),
        onPressed: () {
          // Navigates to role-filtered login [cite: 1]
        },
      ),
    );
  }
}