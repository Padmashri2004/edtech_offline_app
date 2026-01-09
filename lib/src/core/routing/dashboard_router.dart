import 'package:flutter/material.dart';
import 'package:edtech_offline_app/src/features/dashboard/presentation/teacher_dashboard.dart';
import 'package:edtech_offline_app/src/features/dashboard/presentation/student_dashboard.dart';
import 'package:edtech_offline_app/src/features/dashboard/presentation/parent_dashboard.dart';
import 'package:edtech_offline_app/src/features/auth/presentation/login_screen.dart';

class DashboardRouter extends StatelessWidget {
  final String? role;
  const DashboardRouter({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case 'teacher': return const TeacherDashboard();
      case 'student': return const StudentDashboard();
      case 'parent': return const ParentDashboard();
      default: return const LoginScreen();
    }
  }
}