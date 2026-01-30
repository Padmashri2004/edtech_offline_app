import 'package:flutter/material.dart';

class ParentNotificationsScreen extends StatelessWidget {
  final Map<String, String> student;

  const ParentNotificationsScreen({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final String studentName = student["name"]!;
    final String className = "${student["class"]} - ${student["section"]}";

    // 🔁 Student-specific notifications WITH time
    final List<Map<String, String>> notifications = studentName == "Aarav"
        ? [
            {
              "text": "Science quiz posted for Class 6A",
              "time": "29 Jan 2026 • 10:30 AM",
            },
            {
              "text": "Assignment deadline tomorrow",
              "time": "28 Jan 2026 • 6:45 PM",
            },
            {
              "text": "Math quiz results published",
              "time": "27 Jan 2026 • 4:15 PM",
            },
          ]
        : [
            {
              "text": "English worksheet shared",
              "time": "29 Jan 2026 • 9:10 AM",
            },
            {
              "text": "Social Science assignment graded",
              "time": "28 Jan 2026 • 5:20 PM",
            },
            {
              "text": "Parent–Teacher meeting scheduled",
              "time": "26 Jan 2026 • 11:00 AM",
            },
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _studentHeader(studentName, className),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return _notificationCard(
                    item["text"]!,
                    item["time"]!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI (UNCHANGED STYLE) ----------

  Widget _studentHeader(String name, String className) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.blueAccent],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                className,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(String text, String time) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.circle, size: 10, color: Colors.indigo),
        title: Text(text),
        subtitle: Text(
          time,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}
