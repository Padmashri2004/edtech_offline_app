import 'package:flutter/material.dart';

class ParentQueriesScreen extends StatefulWidget {
  const ParentQueriesScreen({super.key});

  @override
  State<ParentQueriesScreen> createState() => _ParentQueriesScreenState();
}

class _ParentQueriesScreenState extends State<ParentQueriesScreen> {
  String selectedClass = "Class 6";
  String selectedSubject = "Science";
  String selectedTeacher = "Mrs. Mary";

  final TextEditingController queryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Post a Query"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _dropdown("Class", selectedClass, ["Class 6", "Class 7"], (v) {
              setState(() => selectedClass = v);
            }),
            _dropdown("Subject", selectedSubject, ["Science", "Math"], (v) {
              setState(() => selectedSubject = v);
            }),
            _dropdown("Teacher", selectedTeacher, ["Mrs. Mary", "Mr. John"],
                (v) {
              setState(() => selectedTeacher = v);
            }),
            const SizedBox(height: 16),
            TextField(
              controller: queryController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Type your query here...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Query sent successfully")),
                );
                queryController.clear();
              },
              child: const Text(
                "Submit Query",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}
