import 'package:flutter/material.dart';
import 'parent_progress_pdf_service.dart';

class ParentProgressScreen extends StatelessWidget {
  final Map<String, String> student;

  const ParentProgressScreen({
    super.key,
    required this.student,
  });

  final String parentName = "Mrs. Anitha";
  final String studentName = "Aarav";
  final String studentClass = "Class 6 - A";

  final int quizAverage = 78;
  final int assignmentsSubmitted = 8;
  final int assignmentsTotal = 10;

  @override
  Widget build(BuildContext context) {
    final studentName = student["name"]!;
    final studentClass = "${student["class"]} - ${student["section"]}";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Student Progress"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _studentInfoCard(),
            const SizedBox(height: 20),
            _sectionTitle("Quiz Performance"),
            _progressCard(
              label: "Average Score",
              value: "$quizAverage%",
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            _sectionTitle("Assignments"),
            _progressCard(
              label: "Submitted",
              value: "$assignmentsSubmitted / $assignmentsTotal",
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            _sectionTitle("Overall Progress"),
            _overallProgressBar(),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text("Download Progress Report (PDF)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ParentProgressPdfService.generateAndPrint(
                    studentName: studentName,
                    studentClass: studentClass,
                    quizAverage: quizAverage,
                    assignmentsSubmitted: assignmentsSubmitted,
                    assignmentsTotal: assignmentsTotal,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentInfoCard() {
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
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.school, color: Colors.indigo, size: 30),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                studentClass,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _progressCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overallProgressBar() {
    double progress = quizAverage / 100;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Overall Performance"),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            color: Colors.indigo,
          ),
          const SizedBox(height: 6),
          Text("${(progress * 100).toInt()}%"),
        ],
      ),
    );
  }
}
