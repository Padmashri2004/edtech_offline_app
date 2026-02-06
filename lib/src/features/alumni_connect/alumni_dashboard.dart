import 'package:flutter/material.dart';
import 'alumni_list_screen.dart';
import 'alumni_requests_screen.dart';

class AlumniDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Alumni Connect"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _card(
              icon: Icons.group,
              title: "Alumni List",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AlumniListScreen()),
                );
              },
            ),
            _card(
              icon: Icons.notifications,
              title: "Requests",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AlumniRequestsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.indigo),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
