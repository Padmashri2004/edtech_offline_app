import 'package:flutter/material.dart';
import 'parent_progress_screen.dart';
import 'connect_teacher.dart';
import 'parent_queries_screen.dart';
import 'parent_notifications_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final String parentName = "Mrs. Lakshmi";

  final List<Map<String, String>> students = [
    {
      "name": "Aarav",
      "class": "Class 6",
      "section": "A",
      "id": "STU101",
    },
    {
      "name": "Ananya",
      "class": "Class 4",
      "section": "B",
      "id": "STU102",
    },
  ];

  int selectedStudentIndex = 0;

  void _navigate(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedStudent = students[selectedStudentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Parent Dashboard"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(selectedStudent),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  _buildDashboardCard(
                    icon: Icons.bar_chart_rounded,
                    title: "Student Progress",
                    subtitle: "Marks & reports",
                    color: Colors.blue,
                    onTap: () => _navigate(
                      ParentProgressScreen(
                        student: students[selectedStudentIndex],
                      ),
                    ),
                  ),
                  _buildDashboardCard(
                    icon: Icons.school,
                    title: "Connect Teacher",
                    subtitle: "Meet or message",
                    color: Colors.green,
                    onTap: () => _navigate(ParentConnectTeacherScreen()),
                  ),
                  _buildDashboardCard(
                    icon: Icons.question_answer,
                    title: "Queries",
                    subtitle: "Ask doubts",
                    color: Colors.orange,
                    onTap: () => _navigate(ParentQueriesScreen()),
                  ),
                  _buildDashboardCard(
                    icon: Icons.notifications,
                    title: "Notifications",
                    subtitle: "Updates & alerts",
                    color: Colors.purple,
                    onTap: () => _navigate(ParentNotificationsScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, String> selectedStudent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.blueAccent],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 36, color: Colors.indigo),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parentName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Parent ID linked",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Children",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(students.length, (index) {
              final student = students[index];
              final isSelected = index == selectedStudentIndex;

              return ChoiceChip(
                label: Text(
                  "${student["name"]} • ${student["class"]}${student["section"]}",
                ),
                selected: isSelected,
                selectedColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.indigo : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Colors.indigo.withOpacity(0.4),
                onSelected: (_) {
                  setState(() {
                    selectedStudentIndex = index;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            "Selected ID: ${selectedStudent["id"]}",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
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
