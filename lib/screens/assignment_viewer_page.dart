import 'package:flutter/material.dart';

class AssignmentViewerPage extends StatelessWidget {
  const AssignmentViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assignment Viewer")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Scanning document...")),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text("Scan Assignment"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Message sent to teacher")),
                );
              },
              icon: const Icon(Icons.message),
              label: const Text("Ask Doubt to Teacher"),
            ),
          ],
        ),
      ),
    );
  }
}
