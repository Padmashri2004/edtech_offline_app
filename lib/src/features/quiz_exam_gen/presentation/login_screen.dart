import 'package:flutter/material.dart';
import 'package:edtech_offline_app/src/core/routing/dashboard_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Simulating a role for demonstration; Member 2 will connect this to Hive/Auth
  String selectedRole = 'Student'; 

  void _handleLogin() {
    // FIX: Access the static method getDashboardForRole and pass the required string
    final Widget nextScreen = DashboardRouter.getDashboardForRole(selectedRole);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Screen")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: selectedRole,
              items: <String>['Teacher', 'Student', 'Parent'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedRole = newValue!;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleLogin,
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}