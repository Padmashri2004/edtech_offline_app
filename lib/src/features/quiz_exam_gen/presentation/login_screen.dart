import 'package:flutter/material.dart';
import 'package:edtech_offline_app/src/features/auth/data/auth_repository.dart';
import 'package:edtech_offline_app/src/features/auth/presentation/registration_screen.dart';
// Import the new state model
import 'package:edtech_offline_app/src/features/auth/presentation/login_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthRepository _authRepo = AuthRepository();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Track the UI state
  LoginState _state = LoginState();
  bool _rememberMe = false;
  String _selectedRole = 'student';

  Future<void> _handleLogin() async {
    setState(() => _state = _state.copyWith(status: AuthStatus.loading));

    try {
      final user = await _authRepo.loginUser(
        _emailController.text.trim(), 
        _passwordController.text.trim(), 
        _rememberMe
      );

      if (user != null) {
        if (user['role'] == _selectedRole) {
          setState(() => _state = _state.copyWith(status: AuthStatus.authenticated, userRole: user['role']));
          _showMsg("Success! Welcome ${user['name']}");
        } else {
          setState(() => _state = _state.copyWith(status: AuthStatus.error, errorMessage: "Role mismatch"));
        }
      } else {
        setState(() => _state = _state.copyWith(status: AuthStatus.error, errorMessage: "Invalid credentials"));
      }
    } catch (e) {
      setState(() => _state = _state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Login", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Show error message if state has one
            if (_state.status == AuthStatus.error)
              Text(_state.errorMessage!, style: const TextStyle(color: Colors.red)),

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
            
            const SizedBox(height: 20),

            // Toggle between Button and Loading Spinner
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
    );
  }
}