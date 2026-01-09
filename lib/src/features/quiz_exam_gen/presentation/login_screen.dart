import 'package:flutter/material.dart';
import 'package:edtech_offline_app/src/features/auth/data/auth_repository.dart';
import 'package:edtech_offline_app/src/features/auth/presentation/registration_screen.dart';
import 'package:edtech_offline_app/src/features/auth/presentation/login_state.dart';
import 'package:edtech_offline_app/src/core/routing/dashboard_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthRepository _authRepo = AuthRepository();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  LoginState _state = LoginState();
  bool _rememberMe = false; 
  String _selectedRole = 'student';

  Future<void> _handleLogin() async {
    setState(() => _state = _state.copyWith(status: AuthStatus.loading));

    final user = await _authRepo.loginUser(
      _emailController.text.trim(), 
      _passwordController.text.trim(), 
      _rememberMe
    );

    if (user != null) {
      if (user['role'] == _selectedRole) {
        setState(() => _state = _state.copyWith(status: AuthStatus.authenticated));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardRouter(role: user['role'])),
          );
        }
      } else {
        setState(() => _state = _state.copyWith(status: AuthStatus.error, errorMessage: "Role mismatch"));
      }
    } else {
      setState(() => _state = _state.copyWith(status: AuthStatus.error, errorMessage: "Invalid credentials"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text("EdTech Login", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                items: const [
                  DropdownMenuItem(value: 'teacher', child: Text("Teacher")),
                  DropdownMenuItem(value: 'student', child: Text("Student")),
                  DropdownMenuItem(value: 'parent', child: Text("Parent")),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Gmail ID")),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
              CheckboxListTile(
                title: const Text("Remember in app"),
                value: _rememberMe,
                onChanged: (val) => setState(() => _rememberMe = val!),
              ),
              const SizedBox(height: 20),
              _state.status == AuthStatus.loading 
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _handleLogin, child: const Text("LOGIN")),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationScreen())),
                child: const Text("Create New Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}