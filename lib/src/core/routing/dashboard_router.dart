import 'package:flutter/material.dart';
import 'package:edtech_offline_app/src/features/dashboard/presentation/teacher_dashboard.dart';
import 'package:edtech_offline_app/src/features/dashboard/presentation/student_dashboard.dart';
import 'package:edtech_offline_app/src/features/dashboard/presentation/parent_dashboard.dart';

class DashboardRouter {
  static Widget getDashboardForRole(String role) {
    switch (role) {
      case 'Teacher':
        return const TeacherDashboard();
      case 'Student':
        return const StudentDashboard();
      case 'Parent':
        return const ParentDashboard();
      default:
        // Since LoginScreen doesn't exist yet, we return a simple Scaffold
        // This stops the "Target of URI doesn't exist" error.
        return const Scaffold(
          body: Center(child: Text("Login Screen Placeholder - Member 2 Task")),
        );
    }
  }

  static Route createRoute(Widget destination) {
    return MaterialPageRoute(builder: (_) => destination);
  }
}