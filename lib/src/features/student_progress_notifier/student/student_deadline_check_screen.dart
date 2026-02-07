import 'package:flutter/material.dart';
import 'student_adaptive_question_screen.dart';
import '../../student_tracking/goal_setter.dart';


class StudentDeadlineCheckScreen extends StatelessWidget {
  const StudentDeadlineCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Deadline Check")),
      body: Center(
        child: ElevatedButton(
          child: const Text("Attempt Readiness Question"),
          onPressed: () async {
  final goalService = GoalSetterService();

  await goalService.completeGoal(
    goalId: 1, // temporary
    studentId: 'student_001',
    chapter: 'Photosynthesis', // or pass dynamically later
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const StudentAdaptiveQuestionScreen(),
    ),
  );
},

        ),
      ),
    );
  }
}
