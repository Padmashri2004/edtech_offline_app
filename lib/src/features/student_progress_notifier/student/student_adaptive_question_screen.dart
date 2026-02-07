import 'package:flutter/material.dart';

class StudentAdaptiveQuestionScreen extends StatefulWidget {
  const StudentAdaptiveQuestionScreen({super.key});

  @override
  State<StudentAdaptiveQuestionScreen> createState() =>
      _StudentAdaptiveQuestionScreenState();
}

class _StudentAdaptiveQuestionScreenState
    extends State<StudentAdaptiveQuestionScreen> {
  final controller = TextEditingController();

  void submit(BuildContext context) {
    final answer = controller.text.toLowerCase();

    if (answer.contains("light")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're ready! Deadline maintained.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Extra time requested from teacher."),
        ),
      );
    }

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quick Check")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "What is the main function of chlorophyll?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: "Your Answer"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => submit(context),
              child: const Text("Submit"),
            )
          ],
        ),
      ),
    );
  }
}
