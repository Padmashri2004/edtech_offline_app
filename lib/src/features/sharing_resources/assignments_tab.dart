import 'package:flutter/material.dart';

class AssignmentsTab extends StatelessWidget {
  const AssignmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final assignments = [
      {
        "title": "Photosynthesis Worksheet",
        "class": "Class 6",
        "subject": "Science",
        "chapter": "Chapter 5",
        "deadline": "Due: 02 Feb 2026",
        "teacher": "Mrs. Mary",
      },
      {
        "title": "Ecosystem Short Notes",
        "class": "Class 6",
        "subject": "Science",
        "chapter": "Chapter 4",
        "deadline": "Due: 04 Feb 2026",
        "teacher": "Mrs. Mary",
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final a = assignments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.assignment, color: Colors.green),
            title: Text(a["title"]!),
            subtitle: Text(
              "${a["class"]}, ${a["subject"]}\n${a["chapter"]}\n${a["deadline"]}",
            ),
            trailing: Text(
              a["teacher"]!,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
