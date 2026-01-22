import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';

class AlumniListScreen extends StatelessWidget {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  AlumniListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Alumni")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Fetches profiles from the database you created
        future: _dbHelper.database.then((db) => db.query('alumni_profiles')),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final alumni = snapshot.data![index];
              return ListTile(
                title: Text(alumni['name']),
                subtitle: Text(alumni['expertise']),
                trailing: const Icon(Icons.person_add),
              );
            },
          );
        },
      ),
    );
  }
}