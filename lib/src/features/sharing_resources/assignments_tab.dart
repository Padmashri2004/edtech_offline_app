import 'package:flutter/material.dart';

class AssignmentsTab extends StatelessWidget {
  const AssignmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _assignmentCard(
          teacher: "Mrs. Mary",
          subject: "Science",
          chapter: "Plants Ecosystem",
          deadline: "Due: 02 Feb 2026",
          description: "Write and explain photosynthesis with diagram.",
        ),
        _assignmentCard(
          teacher: "Mr. John",
          subject: "Maths",
          chapter: "Algebra",
          deadline: "Due: 04 Feb 2026",
          description: "Solve Exercise 3.1 completely.",
        ),
      ],
    );
  }

  Widget _assignmentCard({
    required String teacher,
    required String subject,
    required String chapter,
    required String deadline,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$teacher • $subject",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text("Chapter: $chapter"),
            const SizedBox(height: 6),
            Text(description),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(deadline,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("View"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
