import 'package:flutter/material.dart';

class ParentQueriesScreen extends StatefulWidget {
  final Map<String, String> student;

  const ParentQueriesScreen({
    super.key,
    required this.student,
  });

  @override
  State<ParentQueriesScreen> createState() => _ParentQueriesScreenState();
}

class _ParentQueriesScreenState extends State<ParentQueriesScreen> {
  final TextEditingController _queryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final String studentName = widget.student["name"]!;
    final String className =
        "${widget.student["class"]} - ${widget.student["section"]}";

    // 🔁 Different teachers per student (for validation)
    final List<String> teachers = studentName == "Aarav"
        ? ["Mrs. Mary (Science)", "Mr. Rajesh (Maths)"]
        : ["Ms. Kavitha (English)", "Mr. Suresh (Social Science)"];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Queries"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _studentHeader(studentName, className),
            const SizedBox(height: 20),
            const Text(
              "Select Teacher",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              items: teachers
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t),
                    ),
                  )
                  .toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            const Text(
              "Enter your query",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _queryController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Type your query here...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white, // ✅ fixed visibility
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Query submitted successfully"),
                    ),
                  );
                  _queryController.clear();
                },
                child: const Text("Submit Query"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI (UNCHANGED STYLE) ----------------

  Widget _studentHeader(String name, String className) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.blueAccent],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                className,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
