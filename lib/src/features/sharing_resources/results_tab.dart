import 'package:flutter/material.dart';

class ResultsTab extends StatelessWidget {
  const ResultsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _resultCard(
          title: "Science Quiz - Chapter 5",
          teacher: "Mrs. Mary",
          average: "Class Avg: 72%",
          published: "Published today",
        ),
        _resultCard(
          title: "Mid Term Exam",
          teacher: "Class Teacher",
          average: "Overall Avg: 68%",
          published: "Published yesterday",
        ),
      ],
    );
  }

  Widget _resultCard({
    required String title,
    required String teacher,
    required String average,
    required String published,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$teacher\n$average"),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.indigo),
            Text(published,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
