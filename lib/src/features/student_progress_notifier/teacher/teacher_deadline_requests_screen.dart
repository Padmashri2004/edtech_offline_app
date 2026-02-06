import 'package:flutter/material.dart';

class TeacherDeadlineRequestsScreen extends StatelessWidget {
  const TeacherDeadlineRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deadline Requests"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: const Text(
                  "Anu",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Requested deadline extension due to low readiness",
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("Deadline extension approved for student"),
                      ),
                    );
                  },
                  child: const Text("Approve"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
