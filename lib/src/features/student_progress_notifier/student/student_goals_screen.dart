import 'package:flutter/material.dart';
import 'student_deadline_check_screen.dart';

class StudentGoalsScreen extends StatefulWidget {
  const StudentGoalsScreen({super.key});

  @override
  State<StudentGoalsScreen> createState() => _StudentGoalsScreenState();
}

class _StudentGoalsScreenState extends State<StudentGoalsScreen> {
  final TextEditingController daysController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Study Goal"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Complete selected topics within:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Number of days",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentDeadlineCheckScreen(),
                  ),
                );
              },
              child: const Text("Save Goal"),
            )
          ],
        ),
      ),
    );
  }
}
