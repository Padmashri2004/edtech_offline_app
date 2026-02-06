import 'package:flutter/material.dart';
import 'student_goals_screen.dart';

class StudentTopicSelectionScreen extends StatefulWidget {
  const StudentTopicSelectionScreen({super.key});

  @override
  State<StudentTopicSelectionScreen> createState() =>
      _StudentTopicSelectionScreenState();
}

class _StudentTopicSelectionScreenState
    extends State<StudentTopicSelectionScreen> {
  final Map<String, bool> topics = {
    "Photosynthesis": false,
    "Respiration": false,
    "Transpiration": false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Topics")),
      body: ListView(
        children: topics.keys.map((topic) {
          return CheckboxListTile(
            title: Text(topic),
            value: topics[topic],
            onChanged: (v) => setState(() => topics[topic] = v!),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.arrow_forward),
        onPressed: () {
          final selectedTopics =
              topics.entries.where((e) => e.value).map((e) => e.key).toList();

          if (selectedTopics.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Select at least one topic")),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentGoalsScreen(topic: selectedTopics.first),
            ),
          );
        },
      ),
    );
  }
}
