import 'package:flutter/material.dart';

class ParentNotificationsScreen extends StatelessWidget {
  const ParentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _notificationCard(
            title: "Quiz Published",
            message: "Science quiz has been posted for Class 6.",
            time: "10 mins ago",
            unread: true,
          ),
          _notificationCard(
            title: "Assignment Deadline",
            message: "Math assignment due tomorrow.",
            time: "2 hrs ago",
            unread: false,
          ),
          _notificationCard(
            title: "Teacher Message",
            message: "Mrs. Mary requested a parent meeting.",
            time: "Yesterday",
            unread: false,
          ),
        ],
      ),
    );
  }

  Widget _notificationCard({
    required String title,
    required String message,
    required String time,
    required bool unread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unread ? Colors.indigo.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            unread ? Icons.notifications_active : Icons.notifications,
            color: Colors.indigo,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(message),
                const SizedBox(height: 6),
                Text(time,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
