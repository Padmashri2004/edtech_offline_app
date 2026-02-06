import 'package:flutter/material.dart';
import 'student_deadline_check_screen.dart';

class StudentGoalsScreen extends StatefulWidget {
  final String topic;
  const StudentGoalsScreen({super.key, required this.topic});

  @override
  State<StudentGoalsScreen> createState() => _StudentGoalsScreenState();
}

class _StudentGoalsScreenState extends State<StudentGoalsScreen> {
  DateTime? targetDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Goal")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Topic: ${widget.topic}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                targetDate == null
                    ? "Select Target Date"
                    : targetDate.toString().split(' ')[0],
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                  initialDate: DateTime.now(),
                );
                if (picked != null) setState(() => targetDate = picked);
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: targetDate == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentDeadlineCheckScreen(),
                        ),
                      );
                    },
              child: const Text("Save Goal"),
            ),
          ],
        ),
      ),
    );
  }
}
