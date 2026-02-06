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
    "Plant Nutrition": false,
    "Transpiration": false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Topics"),
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: topics.keys.map((topic) {
          return CheckboxListTile(
            title: Text(topic),
            value: topics[topic],
            onChanged: (val) {
              setState(() => topics[topic] = val!);
            },
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.arrow_forward),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StudentGoalsScreen(),
            ),
          );
        },
      ),
    );
  }
}
