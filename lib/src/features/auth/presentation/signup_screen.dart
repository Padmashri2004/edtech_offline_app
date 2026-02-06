import 'package:flutter/material.dart';
import '../data/auth_db.dart';
import '../data/user_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  String role = 'Teacher';
  String salutation = 'Ms';

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  // ---------- STUDENT ----------
  String? studentClass;
  String? studentSection;

  // ---------- TEACHER ----------
  bool handlesClasses = false;
  bool handlesSubjects = false;
  bool isClassTeacher = false;

  String? classTeacherClass;
  String? classTeacherSection;

  final List<String> classList = [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
    'XI',
    'XII'
  ];
  final List<String> sectionList = ['A', 'B', 'C', 'D'];
  final List<String> subjectList = [
    'Maths',
    'Science',
    'English',
    'Social',
    'Computer'
  ];

  final Set<String> selectedClasses = {};
  final Set<String> selectedSubjects = {};

  // ---------- PARENT ----------
  final List<Map<String, TextEditingController>> children = [];

  bool _validPassword(String v) {
    return v.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(v) &&
        RegExp(r'[0-9]').hasMatch(v);
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;

    if (role == 'Teacher') {
      if (handlesClasses && selectedClasses.isEmpty) {
        _error('Select at least one class handled');
        return;
      }
      if (handlesSubjects && selectedSubjects.isEmpty) {
        _error('Select at least one subject handled');
        return;
      }
      if (isClassTeacher &&
          (classTeacherClass == null || classTeacherSection == null)) {
        _error('Class teacher details required');
        return;
      }
    }

    if (role == 'Parent' && children.isEmpty) {
      _error('Add at least one child');
      return;
    }

    AuthDB.instance.register(
      UserModel(
        role: role,
        salutation: salutation,
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        studentClass: studentClass,
        studentSection: studentSection,
        classesHandled: selectedClasses.toList(),
        subjectsHandled: selectedSubjects.toList(),
        isClassTeacher: isClassTeacher,
        classTeacherClass: classTeacherClass,
        classTeacherSection: classTeacherSection,
        children: children
            .map((c) => {
                  'name': c['name']!.text,
                  'class': c['class']!.text,
                  'section': c['section']!.text,
                  'studentEmail': c['studentEmail']!.text,
                })
            .toList(),
      ),
    );

    Navigator.pop(context);
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: const [
                          Icon(Icons.person_add,
                              size: 48, color: Colors.indigo),
                          SizedBox(height: 8),
                          Text(
                            'Create Account',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _section('Basic Info'),
                    _dropdown(
                      value: salutation,
                      label: 'Salutation',
                      icon: Icons.badge,
                      items: ['Ms', 'Mr', 'Mrs'],
                      onChanged: (v) => setState(() => salutation = v!),
                    ),
                    _text(nameCtrl, 'Full Name', Icons.person,
                        validator: (v) => v!.isEmpty ? 'Name required' : null),
                    _dropdown(
                      value: role,
                      label: 'Role',
                      icon: Icons.work,
                      items: ['Teacher', 'Student', 'Parent'],
                      onChanged: (v) => setState(() => role = v!),
                    ),
                    _section('Account Credentials'),
                    _text(emailCtrl, 'Gmail ID', Icons.email,
                        validator: (v) => v!.isEmpty ? 'Email required' : null),
                    _text(passCtrl, 'Password', Icons.lock, obscure: true,
                        validator: (v) {
                      if (v!.isEmpty) return 'Password required';
                      if (!_validPassword(v)) {
                        return '8 chars, 1 capital, 1 number';
                      }
                      return null;
                    }),
                    _text(confirmCtrl, 'Confirm Password', Icons.lock_outline,
                        obscure: true,
                        validator: (v) => v != passCtrl.text
                            ? 'Passwords do not match'
                            : null),
                    if (role == 'Student') ...[
                      _section('Student Details'),
                      _dropdown(
                        value: studentClass,
                        label: 'Class',
                        icon: Icons.school,
                        items: classList,
                        validator: (v) => v == null ? 'Select class' : null,
                        onChanged: (v) => setState(() => studentClass = v),
                      ),
                      _dropdown(
                        value: studentSection,
                        label: 'Section',
                        icon: Icons.group,
                        items: sectionList,
                        validator: (v) => v == null ? 'Select section' : null,
                        onChanged: (v) => setState(() => studentSection = v),
                      ),
                    ],
                    if (role == 'Teacher') ...[
                      _section('Teacher Details'),
                      SwitchListTile(
                        title: const Text('Handles Classes'),
                        value: handlesClasses,
                        onChanged: (v) => setState(() => handlesClasses = v),
                      ),
                      if (handlesClasses)
                        _multiSelect(
                          'Select Class',
                          classList,
                          selectedClasses,
                        ),
                      SwitchListTile(
                        title: const Text('Handles Subjects'),
                        value: handlesSubjects,
                        onChanged: (v) => setState(() => handlesSubjects = v),
                      ),
                      if (handlesSubjects)
                        _multiSelect(
                          'Select Subject',
                          subjectList,
                          selectedSubjects,
                        ),
                      SwitchListTile(
                        title: const Text('Class Teacher'),
                        value: isClassTeacher,
                        onChanged: (v) => setState(() => isClassTeacher = v),
                      ),
                      if (isClassTeacher) ...[
                        _dropdown(
                          value: classTeacherClass,
                          label: 'Class',
                          icon: Icons.school,
                          items: classList,
                          validator: (v) => v == null ? 'Required' : null,
                          onChanged: (v) =>
                              setState(() => classTeacherClass = v),
                        ),
                        _dropdown(
                          value: classTeacherSection,
                          label: 'Section',
                          icon: Icons.group,
                          items: sectionList,
                          validator: (v) => v == null ? 'Required' : null,
                          onChanged: (v) =>
                              setState(() => classTeacherSection = v),
                        ),
                      ],
                    ],
                    if (role == 'Parent') ...[
                      _section('Children Details'),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            children.add({
                              'name': TextEditingController(),
                              'class': TextEditingController(),
                              'section': TextEditingController(),
                              'studentEmail': TextEditingController(),
                            });
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Child'),
                      ),
                      ...children.map((c) => Card(
                            margin: const EdgeInsets.only(top: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  _text(
                                      c['name']!, 'Student Name', Icons.person,
                                      validator: (v) =>
                                          v!.isEmpty ? 'Required' : null),
                                  _text(c['class']!, 'Class', Icons.school),
                                  _text(c['section']!, 'Section', Icons.group),
                                  _text(
                                      c['studentEmail']!,
                                      'Student Gmail / Profile ID',
                                      Icons.email),
                                ],
                              ),
                            ),
                          )),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Register'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  Widget _text(TextEditingController c, String label, IconData icon,
      {bool obscure = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dropdown({
    String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        validator: validator,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _multiSelect(String label, List<String> list, Set<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: list
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => selected.add(v));
          },
        ),
        Wrap(
          spacing: 8,
          children: selected
              .map((e) => Chip(
                    label: Text(e),
                    onDeleted: () => setState(() => selected.remove(e)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
