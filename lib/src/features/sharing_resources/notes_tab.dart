import 'package:flutter/material.dart';

class NotesTab extends StatelessWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _noteCard(
          teacher: "Mrs. Mary",
          classInfo: "Class 6 - Science",
          chapter: "Chapter 5: Plants Ecosystem",
          topic: "Photosynthesis",
          type: "PDF + Video",
          time: "2 hrs ago",
        ),
        _noteCard(
          teacher: "Mr. John",
          classInfo: "Class 7 - Maths",
          chapter: "Chapter 3: Algebra",
          topic: "Linear Equations",
          type: "Handwritten Notes",
          time: "Yesterday",
        ),
      ],
    );
  }

  Widget _noteCard({
    required String teacher,
    required String classInfo,
    required String chapter,
    required String topic,
    required String type,
    required String time,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(teacher,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(classInfo, style: const TextStyle(color: Colors.grey)),
            const Divider(),
            Text(chapter),
            Text("Topic: $topic"),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(label: Text(type)),
                Text(time, style: const TextStyle(color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
