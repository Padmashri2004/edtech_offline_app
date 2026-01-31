import 'package:flutter/material.dart';

class ResultsTab extends StatelessWidget {
  const ResultsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final results = [
      {
        "title": "Science Quiz – Chapter 5",
        "score": "18 / 20",
        "sharedBy": "Mrs. Mary",
        "time": "Today",
      },
      {
        "title": "Mid-Term Exam – Science",
        "score": "78 / 100",
        "sharedBy": "Mrs. Mary",
        "time": "Yesterday",
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final r = results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.orange),
            title: Text(r["title"]!),
            subtitle: Text("Score: ${r["score"]}"),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(r["sharedBy"]!, style: const TextStyle(fontSize: 12)),
                Text(r["time"]!, style: const TextStyle(fontSize: 11)),
              ],
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Opening result PDF...")),
              );
            },
          ),
        );
      },
    );
  }
}
