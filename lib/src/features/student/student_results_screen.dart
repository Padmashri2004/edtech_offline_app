import 'package:flutter/material.dart';

class StudentResultsScreen extends StatelessWidget {
  const StudentResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final results = [
      {
        "title": "Science Quiz – Chapter 5",
        "score": "18 / 20",
        "percentage": "90%",
        "sharedBy": "Mrs. Mary",
        "time": "Today • 10:30 AM",
      },
      {
        "title": "Math Unit Test",
        "score": "42 / 50",
        "percentage": "84%",
        "sharedBy": "Mr. John",
        "time": "28 Jan • 2:15 PM",
      },
      {
        "title": "Mid-Term Examination",
        "score": "365 / 500",
        "percentage": "73%",
        "sharedBy": "Class Teacher",
        "time": "15 Jan • 11:00 AM",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Results"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final r = results[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              title: Text(
                r["title"]!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "Score: ${r["score"]}  •  ${r["percentage"]}",
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    r["sharedBy"]!,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r["time"]!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Opening result PDF…"),
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
