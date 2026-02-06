import 'package:flutter/material.dart';
import '../models/learning_post_model.dart';
import 'learning_post_preview_screen.dart';

class CreateLearningPostScreen extends StatefulWidget {
  const CreateLearningPostScreen({super.key});

  @override
  State<CreateLearningPostScreen> createState() =>
      _CreateLearningPostScreenState();
}

class _CreateLearningPostScreenState extends State<CreateLearningPostScreen> {
  final TextEditingController _contentController = TextEditingController();

  String selectedClass = 'Class 6';
  String selectedSubject = 'Science';
  String selectedChapter = 'Plants';
  String selectedTopic = 'Photosynthesis';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Create Learning Post"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _dropdown(
              label: "Class",
              value: selectedClass,
              items: const ['Class 6', 'Class 7', 'Class 8'],
              onChanged: (v) => setState(() => selectedClass = v),
            ),
            _dropdown(
              label: "Subject",
              value: selectedSubject,
              items: const ['Science', 'Maths', 'English'],
              onChanged: (v) => setState(() => selectedSubject = v),
            ),
            _dropdown(
              label: "Chapter",
              value: selectedChapter,
              items: const ['Plants', 'Nutrition', 'Motion'],
              onChanged: (v) => setState(() => selectedChapter = v),
            ),
            _dropdown(
              label: "Topic",
              value: selectedTopic,
              items: const ['Photosynthesis', 'Respiration', 'Transpiration'],
              onChanged: (v) => setState(() => selectedTopic = v),
            ),
            const SizedBox(height: 16),
            const Text(
              "Your Tip / Trick",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Explain the concept in your own words...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _goToPreview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text("Preview Post"),
            ),
          ],
        ),
      ),
    );
  }

  void _goToPreview() {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter some content")),
      );
      return;
    }

    final post = LearningPost(
      studentName: "Aarav",
      className: selectedClass,
      subject: selectedSubject,
      chapter: selectedChapter,
      topic: selectedTopic,
      content: _contentController.text,
      badge: "Smart Tip ⭐",
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningPostPreviewScreen(post: post),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
