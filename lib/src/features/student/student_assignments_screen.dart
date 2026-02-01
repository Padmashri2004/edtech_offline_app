import 'package:flutter/material.dart';

class StudentAssignmentsScreen extends StatelessWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assignments = [
      {
        "title": "Photosynthesis Worksheet",
        "subject": "Science",
        "deadline": "02 Feb 2026",
        "status": "Pending",
      },
      {
        "title": "Fractions Practice",
        "subject": "Math",
        "deadline": "28 Jan 2026",
        "status": "Submitted",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Assignments"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          final a = assignments[index];
          final submitted = a["status"] == "Submitted";

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              title: Text(
                a["title"] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${a["subject"]} • Deadline: ${a["deadline"]}",
              ),
              trailing: Chip(
                label: Text(a["status"] as String),
                backgroundColor:
                    submitted ? Colors.green.shade100 : Colors.red.shade100,
                labelStyle: TextStyle(
                  color: submitted ? Colors.green : Colors.red,
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      submitted
                          ? "Assignment already submitted"
                          : "Upload assignment (scan / PDF)",
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
