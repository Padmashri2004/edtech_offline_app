import 'package:flutter/material.dart';
import '../widgets/progress_tile.dart';
import 'student_topic_selection_screen.dart';
import 'student_deadline_check_screen.dart';
import 'package:provider/provider.dart';
import '../../student_tracking/progress_notifier.dart';


class StudentProgressDashboard extends StatefulWidget {

  const StudentProgressDashboard({super.key});
@override
State<StudentProgressDashboard> createState() => _StudentProgressDashboardState();
}

class _StudentProgressDashboardState extends State<StudentProgressDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProgressNotifier>().loadStudentProgress('student_001');
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("My Progress")),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ProgressTile(
            title: "My Goals",
            subtitle: "Track subject & topic goals",
            icon: Icons.flag,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentTopicSelectionScreen(),
                ),
              );
            },
          ),
          ProgressTile(
            title: "Assignment Deadline Check",
            subtitle: "Check readiness before submission",
            icon: Icons.assignment,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentDeadlineCheckScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          Consumer<ProgressNotifier>(
            builder: (context, notifier, _) {
              if (notifier.studentProgress.isEmpty) {
                return const Text("No goals added yet");
              }

              return Expanded(
                child: ListView.builder(
                  itemCount: notifier.studentProgress.length,
                  itemBuilder: (context, index) {
                    final item = notifier.studentProgress[index];
                    return ListTile(
                      title: Text(item['chapter']),
                      subtitle:
                          Text("Progress: ${item['progress_percent']}%"),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}}