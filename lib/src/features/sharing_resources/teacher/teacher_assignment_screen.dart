import 'package:flutter/material.dart';

class TeacherAssignmentScreen extends StatefulWidget {
  const TeacherAssignmentScreen({super.key});

  @override
  State<TeacherAssignmentScreen> createState() =>
      _TeacherAssignmentScreenState();
}

class _TeacherAssignmentScreenState extends State<TeacherAssignmentScreen> {
  String selectedClass = 'Class 6';
  String selectedSubject = 'Science';
  String selectedChapter = 'Chapter 5';
  String selectedTopic = 'Photosynthesis';

  DateTime? selectedDeadline;
  final TextEditingController descriptionController = TextEditingController();

  final List<String> classes = ['Class 6', 'Class 7', 'Class 8'];
  final List<String> subjects = ['Science', 'Maths', 'English'];
  final List<String> chapters = ['Chapter 1', 'Chapter 2', 'Chapter 5'];
  final List<String> topics = [
    'Introduction',
    'Photosynthesis',
    'Examples',
    'Summary'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Post Assignment"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dropdown("Class", classes, selectedClass,
                (v) => setState(() => selectedClass = v)),
            _dropdown("Subject", subjects, selectedSubject,
                (v) => setState(() => selectedSubject = v)),
            _dropdown("Chapter", chapters, selectedChapter,
                (v) => setState(() => selectedChapter = v)),
            _dropdown("Topic", topics, selectedTopic,
                (v) => setState(() => selectedTopic = v)),
            const SizedBox(height: 16),
            const Text(
              "Assignment Description",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Describe the assignment clearly...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Deadline",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDeadline,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDeadline == null
                          ? "Select deadline"
                          : "${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}",
                    ),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Assignment posted successfully"),
                    ),
                  );
                },
                child: const Text("Post Assignment"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() => selectedDeadline = picked);
    }
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
}
