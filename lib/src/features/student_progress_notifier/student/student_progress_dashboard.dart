import 'package:flutter/material.dart';
import '../widgets/progress_tile.dart';
import 'student_topic_selection_screen.dart';
import 'student_deadline_check_screen.dart';

class StudentProgressDashboard extends StatelessWidget {
  const StudentProgressDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Progress")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProgressTile(
              title: "My Goals",
              subtitle: "Track subject & topic goals",
              icon: Icons.flag,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentTopicSelectionScreen(),
                  ),
                );
              },
            ),
            ProgressTile(
              title: "Assignment Deadline Check",
              subtitle: "Check readiness before submission",
              icon: Icons.assignment,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentDeadlineCheckScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
