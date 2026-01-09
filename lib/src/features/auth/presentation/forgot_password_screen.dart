import 'package:flutter/material.dart';
import 'package:edtech_offline_app/src/features/auth/data/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authRepo = AuthRepository();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  bool _isEmailVerified = false;

  void _verifyAndReset() async {
    if (!_isEmailVerified) {
      // Step 1: Check if user exists in SQLite
      bool exists = await _authRepo.verifyEmailExists(_emailController.text.trim());
      if (exists) {
        setState(() => _isEmailVerified = true);
        _showMsg("Email verified. Enter new password.");
      } else {
        _showMsg("No account found with this email.");
      }
    } else {
      // Step 2: Update the password in SQLite
      await _authRepo.updatePassword(
        _emailController.text.trim(), 
        _newPasswordController.text.trim()
      );
      _showMsg("Password updated successfully!");
      if (mounted) Navigator.pop(context);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              enabled: !_isEmailVerified,
              decoration: const InputDecoration(labelText: "Enter Registered Gmail ID"),
            ),
            if (_isEmailVerified) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: "Enter New Password"),
                obscureText: true,
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _verifyAndReset,
              child: Text(_isEmailVerified ? "UPDATE PASSWORD" : "VERIFY EMAIL"),
            ),
          ],
        ),
      ),
    );
  }
}