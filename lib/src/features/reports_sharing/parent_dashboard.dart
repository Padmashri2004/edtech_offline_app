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
      "id": "STU001",
    },
    {
      "name": "Ananya",
      "class": "Class 8",
      "section": "B",
      "id": "STU002",
    },
  ];

  late Map<String, String> selectedStudent;

  @override
  void initState() {
    super.initState();
    selectedStudent = students.first;
  }

  void _navigate(Widget screen) {
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
            _buildProfileCard(),
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
                      ParentProgressScreen(student: selectedStudent),
                    ),
                  ),
                  _buildDashboardCard(
                    icon: Icons.school,
                    title: "Connect Teacher",
                    subtitle: "Meet or message",
                    color: Colors.green,
                    onTap: () => _navigate(
                      ParentConnectTeacherScreen(student: selectedStudent),
                    ),
                  ),
                  _buildDashboardCard(
                    icon: Icons.question_answer,
                    title: "Queries",
                    subtitle: "Ask doubts",
                    color: Colors.orange,
                    onTap: () => _navigate(
                      ParentQueriesScreen(student: selectedStudent),
                    ),
                  ),
                  _buildDashboardCard(
                    icon: Icons.notifications,
                    title: "Notifications",
                    subtitle: "Updates & alerts",
                    color: Colors.purple,
                    onTap: () => _navigate(
                      ParentNotificationsScreen(student: selectedStudent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
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
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 36, color: Colors.indigo),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
                const SizedBox(height: 6),
                DropdownButton<Map<String, String>>(
                  value: selectedStudent,
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  underline: Container(),
                  onChanged: (value) {
                    setState(() {
                      selectedStudent = value!;
                    });
                  },
                  items: students.map((student) {
                    return DropdownMenuItem(
                      value: student,
                      child: Text(
                        "${student["name"]} – ${student["class"]}${student["section"]}",
                        style: const TextStyle(color: Colors.black),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
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
