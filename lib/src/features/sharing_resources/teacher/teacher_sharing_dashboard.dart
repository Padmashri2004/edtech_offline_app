import 'package:flutter/material.dart';
import 'teacher_notes_screen.dart';
import 'teacher_assignment_screen.dart';
import 'teacher_results_screen.dart';

class TeacherSharingDashboard extends StatelessWidget {
  const TeacherSharingDashboard({super.key});

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Sharing Resources"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1,
          children: [
            _dashboardCard(
              context,
              icon: Icons.note_alt,
              title: "Notes",
              subtitle: "Share study materials",
              color: Colors.blue,
              onTap: () => _navigate(
                context,
                const TeacherNotesScreen(),
              ),
            ),
            _dashboardCard(
              context,
              icon: Icons.assignment,
              title: "Assignments",
              subtitle: "Post & manage work",
              color: Colors.green,
              onTap: () => _navigate(
                context,
                const TeacherAssignmentScreen(),
              ),
            ),
            _dashboardCard(
              context,
              icon: Icons.bar_chart,
              title: "Results",
              subtitle: "Quiz & exam marks",
              color: Colors.purple,
              onTap: () => _navigate(
                context,
                const TeacherResultsScreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
