import 'package:flutter/material.dart';

class ParentConnectTeacherScreen extends StatelessWidget {
  final Map<String, String> student;

  const ParentConnectTeacherScreen({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final String className = "${student["class"]} - ${student["section"]}";
    final String studentName = student["name"]!;

    // 🔁 DIFFERENT teachers per student (for verification)
    final List<Map<String, String>> teachers = studentName == "Aarav"
        ? [
            {
              "name": "Mrs. Mary",
              "subject": "Science",
            },
            {
              "name": "Mr. Rajesh",
              "subject": "Mathematics",
            },
          ]
        : [
            {
              "name": "Ms. Kavitha",
              "subject": "English",
            },
            {
              "name": "Mr. Suresh",
              "subject": "Social Science",
            },
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Connect with Teacher"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _studentHeader(studentName, className),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: teachers.length,
                itemBuilder: (context, index) {
                  final teacher = teachers[index];
                  return _teacherCard(
                    context,
                    teacher["name"]!,
                    teacher["subject"]!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI (UNCHANGED STYLE) ----------------

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
          const Icon(Icons.school, color: Colors.white, size: 32),
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

  Widget _teacherCard(
    BuildContext context,
    String teacherName,
    String subject,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.indigo,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(teacherName),
        subtitle: Text(subject),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            _showConnectDialog(context, teacherName);
          },
          child: const Text("Connect"),
        ),
      ),
    );
  }

  void _showConnectDialog(BuildContext context, String teacherName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Connect with Teacher"),
        content: const Text(
          "Would you like to connect virtually or physical meet?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Virtual"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Physical"),
          ),
        ],
      ),
    );
  }
}
