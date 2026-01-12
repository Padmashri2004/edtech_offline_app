import 'package:flutter/material.dart';
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

class EdTechApp extends StatelessWidget {
  const EdTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      ),
    );
  }
}