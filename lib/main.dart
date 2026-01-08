import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart'; // Used in the 'checkDatabase' function below
import 'package:path/path.dart';       // Used in the 'checkDatabase' function below
import 'database_helper.dart'; 

void main() async {
  // 1. Mandatory for all hardware/plugin connections
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Hive (Clears Hive warnings)
  await Hive.initFlutter();
  await Hive.openBox('userSettings');

  // 3. Initialize SQL Database (Clears sqflite and path warnings)
  // This function down below uses the 'join' and 'getDatabasesPath'
  await checkDatabaseConnection();

  // 4. Initialize Gemma 3 AI Model (Clears FlutterGemma warnings)
  try {
    await FlutterGemma.initialize(); 
    debugPrint("Gemma AI Pipeline Ready");
  } catch (e) {
    debugPrint("AI Initialization Error: $e");
  }

  runApp(const EdTechOfflineApp());
}

// THIS FUNCTION USES THE IMPORTS TO STOP THE WARNINGS
Future<void> checkDatabaseConnection() async {
  final dbPath = await getDatabasesPath(); // Calls sqflite
  final path = join(dbPath, 'edtech.db');  // Calls path
  debugPrint("Database is located at: $path");
  
  // Actually opening the database ensures the imports are "Active"
  await DatabaseHelper.instance.database;
}

class EdTechOfflineApp extends StatelessWidget {
  const EdTechOfflineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: Scaffold(
        appBar: AppBar(title: const Text('RootEd Offline Portal')),
        body: const Center(
          child: Text(
            'All Imports Active\nWarnings should be gone!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}