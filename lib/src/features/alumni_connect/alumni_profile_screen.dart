import 'package:flutter/material.dart';
import 'models/alumni_model.dart';
import 'alumni_chat_screen.dart';

class AlumniProfileScreen extends StatelessWidget {
  final AlumniModel alumni;

  AlumniProfileScreen({required this.alumni});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(alumni.name),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 12),
            Text(alumni.profileId),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlumniChatScreen(alumni: alumni),
                  ),
                );
              },
              child: const Text("Connect"),
            ),
          ],
        ),
      ),
    );
  }
}
