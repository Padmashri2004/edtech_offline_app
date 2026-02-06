import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String role = 'Teacher';

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  void _login() {
    if (_formKey.currentState!.validate()) {
      // Auth handled elsewhere
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Center(
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 48, color: Colors.indigo),
                  const SizedBox(height: 12),
                  const Text(
                    'LOGIN',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: ['Teacher', 'Student', 'Parent']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => role = v!),
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailCtrl,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Email required' : null,
                    decoration: const InputDecoration(
                      labelText: 'Gmail ID',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Password required' : null,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot'),
                    child: const Text('Forgot Password?'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text('Create New Account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
