import 'package:flutter/material.dart';

class TeacherNotesScreen extends StatefulWidget {
  const TeacherNotesScreen({super.key});

  @override
  State<TeacherNotesScreen> createState() => _TeacherNotesScreenState();
}

class _TeacherNotesScreenState extends State<TeacherNotesScreen> {
  String selectedClass = 'Class 6';
  String selectedSubject = 'Science';
  String selectedChapter = 'Chapter 5';
  String selectedTopic = 'Photosynthesis';

  final TextEditingController noteTextController = TextEditingController();
  final TextEditingController videoLinkController = TextEditingController();

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
        title: const Text("Share Notes"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dropdown("Class", classes, selectedClass, (v) {
              setState(() => selectedClass = v);
            }),
            _dropdown("Subject", subjects, selectedSubject, (v) {
              setState(() => selectedSubject = v);
            }),
            _dropdown("Chapter", chapters, selectedChapter, (v) {
              setState(() => selectedChapter = v);
            }),
            _dropdown("Topic", topics, selectedTopic, (v) {
              setState(() => selectedTopic = v);
            }),
            const SizedBox(height: 16),

            // Text Notes
            const Text(
              "Text Notes",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteTextController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Type notes here...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Video Link
            const Text(
              "Video Link",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: videoLinkController,
              decoration: InputDecoration(
                hintText: "Paste video link",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Upload placeholders
            Row(
              children: [
                _uploadChip(Icons.picture_as_pdf, "Upload PDF"),
                const SizedBox(width: 10),
                _uploadChip(Icons.edit, "Handwritten Notes"),
              ],
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
                      content: Text("Notes shared successfully"),
                    ),
                  );
                },
                child: const Text("Share Notes"),
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

  Widget _uploadChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: Colors.indigo.withOpacity(0.1),
    );
  }
}
