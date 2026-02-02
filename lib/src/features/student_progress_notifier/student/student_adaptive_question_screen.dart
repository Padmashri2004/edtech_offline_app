import 'package:flutter/material.dart';

class StudentAdaptiveQuestionScreen extends StatefulWidget {
  const StudentAdaptiveQuestionScreen({super.key});

  @override
  State<StudentAdaptiveQuestionScreen> createState() =>
      _StudentAdaptiveQuestionScreenState();
}

class _StudentAdaptiveQuestionScreenState
    extends State<StudentAdaptiveQuestionScreen> {
  int? selectedOption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quick Concept Check"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Which process helps plants prepare food?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            RadioListTile<int>(
              value: 1,
              groupValue: selectedOption,
              title: const Text("Respiration"),
              onChanged: (v) => setState(() => selectedOption = v),
            ),
            RadioListTile<int>(
              value: 2,
              groupValue: selectedOption,
              title: const Text("Photosynthesis"),
              onChanged: (v) => setState(() => selectedOption = v),
            ),
            RadioListTile<int>(
              value: 3,
              groupValue: selectedOption,
              title: const Text("Transpiration"),
              onChanged: (v) => setState(() => selectedOption = v),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                final correct = selectedOption == 2;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      correct
                          ? "Correct! Deadline maintained ✅"
                          : "Teacher notified for deadline extension ⏳",
                    ),
                  ),
                );
              },
              child: const Text("Submit Answer"),
            )
          ],
        ),
      ),
    );
  }
}
