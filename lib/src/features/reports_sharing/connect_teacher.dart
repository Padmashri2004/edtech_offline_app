import 'package:flutter/material.dart';

class ParentConnectTeacherScreen extends StatefulWidget {
  const ParentConnectTeacherScreen({super.key});

  @override
  State<ParentConnectTeacherScreen> createState() =>
      _ParentConnectTeacherScreenState();
}

class _ParentConnectTeacherScreenState
    extends State<ParentConnectTeacherScreen> {
  String selectedClass = 'Class 6';
  String selectedSubject = 'Science';
  String selectedTeacher = 'Mrs. Mary';

  String meetingType = 'Virtual';

  final List<String> classes = ['Class 6', 'Class 7', 'Class 8'];
  final List<String> subjects = ['Science', 'Maths', 'English'];
  final List<String> teachers = ['Mrs. Mary', 'Mr. John', 'Ms. Anita'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Connect with Teacher"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dropdown("Select Class", classes, selectedClass,
                (val) => setState(() => selectedClass = val)),
            _dropdown("Select Subject", subjects, selectedSubject,
                (val) => setState(() => selectedSubject = val)),
            _dropdown("Select Teacher", teachers, selectedTeacher,
                (val) => setState(() => selectedTeacher = val)),
            const SizedBox(height: 20),
            _meetingTypeSelector(),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text("Send Request"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _showConfirmation(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String value,
      Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 4, offset: Offset(0, 3)),
              ],
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => onChanged(val!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _meetingTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Meeting Type",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            _radioTile("Virtual"),
            const SizedBox(width: 10),
            _radioTile("Physical"),
          ],
        ),
      ],
    );
  }

  Widget _radioTile(String type) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => meetingType = type),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: meetingType == type
                ? Colors.indigo.withOpacity(0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: meetingType == type ? Colors.indigo : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                meetingType == type
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: Colors.indigo,
              ),
              const SizedBox(width: 6),
              Text(type),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Request Sent"),
        content: Text(
            "Your request to connect with $selectedTeacher has been sent."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}
