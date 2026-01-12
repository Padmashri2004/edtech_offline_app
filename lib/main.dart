import 'package:flutter/material.dart';
<<<<<<< HEAD
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
=======
import 'package:provider/provider.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
// Core Imports
import 'package:edtech_offline_app/src/core/database/database_helper.dart'; 
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';
// Feature Imports
import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/ai_assistant/presentation/ai_chat_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize On-Device AI Pipeline
  await _initAiEngine();

  // 2. Initialize Core Database
  await DatabaseHelper.instance.database;

  // 3. Setup Dependencies for Member 1
  final aiService = AIService();
  final aiRepository = AIRepository(aiService);
>>>>>>> f4a6942 (finalized offline AI engine, textbook parser, and quiz persistence)

  // 4. Run App with Provider injection
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AIChatController(aiRepository),
        ),
      ],
      child: const EdTechApp(),
    ),
  );
}

<<<<<<< HEAD
=======
/// Member 1: AI Model Initialization Logic
Future<void> _initAiEngine() async {
  try {
    await FlutterGemma.initialize();

    // Link to your local asset model
    // Using gemma.task as established in your assets folder
    await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
    ).fromAsset('assets/models/gemma.task').install();
    
    debugPrint("✅ Member 1: Offline AI Engine Ready");
  } catch (e) {
    debugPrint("❌ Member 1: AI Init Error: $e");
  }
}

>>>>>>> f4a6942 (finalized offline AI engine, textbook parser, and quiz persistence)
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
<<<<<<< HEAD
      title: 'EdTech Offline',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
=======
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: Colors.blue,
      ),
      home: const RoleSelectionScreen(),
      routes: {
        '/login': (context) => const Placeholder(),
        '/teacher-dashboard': (context) => const Placeholder(),
      },
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Offline EdTech Portal")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Select Your Role to Login", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 30),
            _roleBtn(context, "Teacher", Icons.school),
            _roleBtn(context, "Student", Icons.person),
            _roleBtn(context, "Parent", Icons.family_restroom),
          ],
        ),
      ),
    );
  }

  Widget _roleBtn(BuildContext context, String role, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text("Continue as $role"),
        onPressed: () {
          debugPrint("Navigating to $role login...");
        },
>>>>>>> f4a6942 (finalized offline AI engine, textbook parser, and quiz persistence)
      ),
      // Auto-Login logic
      home: isLoggedIn 
          ? DashboardRouter(role: userRole) 
          : const LoginScreen(),
    );
  }
}