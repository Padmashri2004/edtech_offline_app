import 'package:flutter/material.dart';

class SubjectSelectionWidget extends StatefulWidget {
  final Function(Map<String, List<String>>) onSubjectsChanged;

  const SubjectSelectionWidget({super.key, required this.onSubjectsChanged});

  @override
  State<SubjectSelectionWidget> createState() => _SubjectSelectionWidgetState();
}

class _SubjectSelectionWidgetState extends State<SubjectSelectionWidget> {
  final Map<String, List<String>> _selectedData = {};

  final List<String> _availableClasses = [
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 
    'Class 5', 'Class 6', 'Class 7', 'Class 8'
  ];
  
  final List<String> _availableSubjects = [
    'Mathematics', 'General Science', 'English', 
    'Social Studies', 'Regional Language'
  ];

  void _toggleSubject(String className, String subject) {
    setState(() {
      if (_selectedData[className] == null) {
        _selectedData[className] = [subject];
      } else {
        if (_selectedData[className]!.contains(subject)) {
          _selectedData[className]!.remove(subject);
          if (_selectedData[className]!.isEmpty) _selectedData.remove(className);
        } else {
          _selectedData[className]!.add(subject);
        }
      }
    });
    widget.onSubjectsChanged(_selectedData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Subjects & Classes Handled:", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        // FIXED: Removed .toList() from spread
        ..._availableClasses.map((className) => ExpansionTile(
          title: Text(className),
          subtitle: Text(
            _selectedData[className]?.join(", ") ?? "No subjects selected",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          children: _availableSubjects.map((subject) => CheckboxListTile(
            title: Text(subject),
            value: _selectedData[className]?.contains(subject) ?? false,
            onChanged: (_) => _toggleSubject(className, subject),
          )).toList(), // Note: children property still requires a List, so toList() stays here.
        )),
      ],
    );
  }
}