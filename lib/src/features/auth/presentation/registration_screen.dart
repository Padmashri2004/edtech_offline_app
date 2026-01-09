import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import 'widgets/subject_selection_widget.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final AuthRepository _repository = AuthRepository();
  final _formKey = GlobalKey<FormState>();

  String _selectedRole = 'student'; 
  String _salutation = 'mr';
  bool _isClassTeacher = false;
  Map<String, List<String>> _teacherSubjects = {};

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      int currentGrade = int.tryParse(_classController.text) ?? 1;
      int gradYear = DateTime.now().year + (8 - currentGrade);

      final Map<String, dynamic> userData = {
        'role': _selectedRole,
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'salutation': _selectedRole == 'teacher' ? _salutation : null,
        'class_id': currentGrade,
        'section': _sectionController.text,
        'is_class_teacher': _isClassTeacher ? 1 : 0,
        'subject_handles': _selectedRole == 'teacher' ? jsonEncode(_teacherSubjects) : null,
        'parent_student_tag': _selectedRole == 'parent' ? _studentIdController.text : null,
        'graduation_year': gradYear,
      };

      await _repository.registerUser(userData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: "Role", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'teacher', child: Text("Teacher")),
                  DropdownMenuItem(value: 'student', child: Text("Student")),
                  DropdownMenuItem(value: 'parent', child: Text("Parent")),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 20),
              
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name")),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: "Gmail ID")),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),

              const Divider(height: 40),

              // FIXED: Removed .toList() from these spreads to resolve lint errors
              if (_selectedRole == 'teacher') ...[
                DropdownButtonFormField<String>(
                  initialValue: _salutation,
                  decoration: const InputDecoration(labelText: "Salutation"),
                  items: const [
                    DropdownMenuItem(value: 'mr', child: Text("Mr.")),
                    DropdownMenuItem(value: 'ms', child: Text("Ms.")),
                    DropdownMenuItem(value: 'mrs', child: Text("Mrs.")),
                  ],
                  onChanged: (val) => setState(() => _salutation = val!),
                ),
                SwitchListTile(
                  title: const Text("Are you a Class Teacher?"),
                  value: _isClassTeacher,
                  onChanged: (val) => setState(() => _isClassTeacher = val),
                ),
                SubjectSelectionWidget(
                  onSubjectsChanged: (data) => _teacherSubjects = data,
                ),
              ],

              if (_selectedRole == 'student') ...[
                TextFormField(controller: _classController, decoration: const InputDecoration(labelText: "Class (1-8)")),
                TextFormField(controller: _sectionController, decoration: const InputDecoration(labelText: "Section")),
              ],

              if (_selectedRole == 'parent') ...[
                TextFormField(controller: _studentIdController, decoration: const InputDecoration(labelText: "Student ID")),
                TextFormField(controller: _classController, decoration: const InputDecoration(labelText: "Student Class")),
              ],

              const SizedBox(height: 30),
              ElevatedButton(onPressed: _handleRegister, child: const Text("REGISTER")),
            ],
          ),
        ),
      ),
    );
  }
}