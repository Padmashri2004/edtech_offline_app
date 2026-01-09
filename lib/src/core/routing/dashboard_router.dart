import 'package:flutter/material.dart';
import 'package:edtech_offline_app/src/features/dashboard/presentation/teacher_dashboard.dart';
import 'package:edtech_offline_app/src/features/dashboard/presentation/student_dashboard.dart';
import 'package:edtech_offline_app/src/features/dashboard/presentation/parent_dashboard.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/login_screen.dart';

class DashboardRouter extends StatelessWidget {
  final String? role;
  const DashboardRouter({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    // The switch logic directs the user to the correct unique class
    switch (role) {
      case 'teacher':
        return const TeacherDashboard();
      case 'student':
        return const StudentDashboard();
      case 'parent':
        return const ParentDashboard();
      case 'alumni':
        return const Scaffold(
          body: Center(child: Text("Alumni Portal: Access to previous records only.")),
        );
      default:
        return const LoginScreen();
    }
  }
}