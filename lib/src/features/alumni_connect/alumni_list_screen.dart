import 'package:flutter/material.dart';
import 'models/alumni_model.dart';
import 'alumni_profile_screen.dart';

class AlumniListScreen extends StatelessWidget {
  final List<AlumniModel> alumni = [
    AlumniModel(name: "Rahul", className: "Class 7", profileId: "AL001"),
    AlumniModel(name: "Sneha", className: "Class 7", profileId: "AL002"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Class 7 Alumni"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: alumni.length,
        itemBuilder: (context, index) {
          final a = alumni[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(a.name),
            subtitle: Text(a.profileId),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlumniProfileScreen(alumni: a),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
