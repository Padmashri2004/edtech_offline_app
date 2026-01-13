import 'package:flutter/material.dart';

class DashboardRouter {
  static Widget getDashboardForRole(String role) {
    switch (role) {
      case 'Teacher':
        return _buildPlaceholderDashboard("Teacher Portal");
      case 'Student':
        return _buildPlaceholderDashboard("Student Portal");
      case 'Parent':
        return _buildPlaceholderDashboard("Parent Portal");
      default:
        return _buildPlaceholderDashboard("Unknown Role");
    }
  }

  /// A temporary placeholder so the app runs without Member 3's files
  static Widget _buildPlaceholderDashboard(String title) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 20),
            Text("$title is under construction."),
            const SizedBox(height: 10),
            const Text("(Member 3 Task)", style: TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  static Route createRoute(Widget destination) {
    return MaterialPageRoute(builder: (_) => destination);
  }
}