import 'package:flutter/material.dart';
import 'teacher_class_overview_screen.dart';
import 'teacher_deadline_requests_screen.dart';

class TeacherProgressDashboard extends StatelessWidget {
  const TeacherProgressDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Progress"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Overview",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Monitor student performance and manage deadline requests.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            Card(
              child: ListTile(
                leading: const Icon(Icons.groups, color: Colors.indigo),
                title: const Text("View Class Progress"),
                subtitle: const Text("Check student goals and performance"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherClassOverviewScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.timer, color: Colors.orange),
                title: const Text("Deadline Requests"),
                subtitle:
                    const Text("Approve or review extension requests"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherDeadlineRequestsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}