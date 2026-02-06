import 'package:flutter/material.dart';

class TeacherResultsScreen extends StatefulWidget {
  const TeacherResultsScreen({super.key});

  @override
  State<TeacherResultsScreen> createState() => _TeacherResultsScreenState();
}

class _TeacherResultsScreenState extends State<TeacherResultsScreen> {
  String selectedClass = 'Class 6';
  String selectedSubject = 'Science';
  String resultType = 'Quiz';

  final List<String> classes = ['Class 6', 'Class 7', 'Class 8'];
  final List<String> subjects = ['Science', 'Maths', 'English'];
  final List<String> resultTypes = ['Quiz', 'Exam'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Share Results"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dropdown(
              "Class",
              classes,
              selectedClass,
              (v) => setState(() => selectedClass = v),
            ),
            _dropdown(
              "Subject",
              subjects,
              selectedSubject,
              (v) => setState(() => selectedSubject = v),
            ),
            _dropdown(
              "Result Type",
              resultTypes,
              resultType,
              (v) => setState(() => resultType = v),
            ),
            const SizedBox(height: 20),
            if (resultType == 'Quiz') _quizResultCard(),
            if (resultType == 'Exam') _examResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _quizResultCard() {
    return _actionCard(
      title: "Share Quiz Results",
      subtitle: "Publish quiz marks from Module 1 to students and parents",
      icon: Icons.assignment_turned_in,
      onTap: () {
        _showSnack("Quiz results shared successfully");
      },
    );
  }

  Widget _examResultCard() {
    return Column(
      children: [
        _actionCard(
          title: "Enter Exam Marks",
          subtitle: "Manually enter subject-wise exam marks for students",
          icon: Icons.edit_note,
          onTap: () {
            _showSnack("Exam marks saved successfully");
          },
        ),
        const SizedBox(height: 16),
        _actionCard(
          title: "Upload Class Marksheet",
          subtitle: "Upload full class marksheet (PDF) across all subjects",
          icon: Icons.upload_file,
          onTap: () {
            _showSnack("Marksheet uploaded successfully");
          },
        ),
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.indigo.withOpacity(0.15),
              child: Icon(icon, color: Colors.indigo, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
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

  Widget _dropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: (v) => onChanged(v!),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}
