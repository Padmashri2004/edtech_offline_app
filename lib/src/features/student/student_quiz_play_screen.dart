import 'package:flutter/material.dart';

class StudentQuizPlayScreen extends StatefulWidget {
  final String quizTitle;

  const StudentQuizPlayScreen({
    super.key,
    required this.quizTitle,
  });

  @override
  State<StudentQuizPlayScreen> createState() => _StudentQuizPlayScreenState();
}

class _StudentQuizPlayScreenState extends State<StudentQuizPlayScreen> {
  int selectedOption = -1;

  final List<Map<String, dynamic>> questions = [
    {
      "question": "Which process do plants use to make food?",
      "options": [
        "Respiration",
        "Photosynthesis",
        "Transpiration",
        "Germination"
      ],
    },
    {
      "question": "Which gas is released during photosynthesis?",
      "options": ["Carbon Dioxide", "Nitrogen", "Oxygen", "Hydrogen"],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.quizTitle),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final List<String> options = List<String>.from(q["options"]);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Q${index + 1}. ${q["question"]}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(
                            options.length,
                            (i) => RadioListTile<int>(
                              value: i,
                              groupValue: selectedOption,
                              title: Text(options[i]),
                              onChanged: (val) {
                                setState(() {
                                  selectedOption = val!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Quiz submitted successfully"),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text("Submit Quiz"),
            ),
          ],
        ),
      ),
    );
  }
}
