import 'package:flutter/material.dart';

class TeacherDeadlineRequestsScreen extends StatelessWidget {
  const TeacherDeadlineRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deadline Requests"),
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Aarav"),
            subtitle: const Text("Needs 2 more days"),
            trailing: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Deadline approved")),
                );
              },
              child: const Text("Approve"),
            ),
          )
        ],
      ),
    );
  }
}
