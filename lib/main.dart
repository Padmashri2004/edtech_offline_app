import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Resolves 'init' isn't defined error for the latest flutter_gemma plugin
  await FlutterGemma.initialize(); 
  
  runApp(const EdTechPortal());
}

class EdTechPortal extends StatelessWidget {
  // Added 'const' and 'key' parameter to satisfy flutter_lints
  const EdTechPortal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: Colors.blueAccent),
      // Directs to the role-based login required by the documentation 
      home: const RoleSelectionScreen(), 
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  // Added 'const' and 'key' parameter to satisfy flutter_lints
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Offline EdTech - Login")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Select User Role", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            // Placeholders for role-specific navigation [cite: 4]
            ElevatedButton(onPressed: () {}, child: const Text("Teacher")),
            ElevatedButton(onPressed: () {}, child: const Text("Student")),
            ElevatedButton(onPressed: () {}, child: const Text("Parent")),
          ],
        ),
      ),
    );
  }
}