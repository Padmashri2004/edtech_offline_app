import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:edtech_offline_app/src/core/database/database_helper.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/login_screen.dart';
import 'package:edtech_offline_app/src/core/routing/dashboard_router.dart';
import 'package:edtech_offline_app/src/core/utils/alumni_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for user persistence
  await Hive.initFlutter();
  await Hive.openBox('settings');
  
  // Initialize SQLite
  await DatabaseHelper.instance.database;

  // 2. Run the Academic Transition Engine (Task 3)
  await AlumniEngine.checkAndPromoteStudents();

  runApp(const EdTechApp());
}

class EdTechApp extends StatelessWidget {
  const EdTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settings');
    // Check if "Remember in app" was previously selected
    final bool isLoggedIn = settingsBox.get('isLoggedIn', defaultValue: false);
    final String? userRole = settingsBox.get('userRole');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EdTech Offline',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      // Auto-Login logic
      home: isLoggedIn 
          ? DashboardRouter(role: userRole) 
          : const LoginScreen(),
    );
  }
}