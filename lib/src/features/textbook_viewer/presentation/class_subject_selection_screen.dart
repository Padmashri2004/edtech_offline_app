import 'package:flutter/material.dart';
import 'package:edtech_offline_app/src/features/textbook_viewer/presentation/chapter_list_screen.dart';

class ClassSubjectSelectionScreen extends StatefulWidget {
  const ClassSubjectSelectionScreen({super.key});

  @override
  State<ClassSubjectSelectionScreen> createState() =>
      _ClassSubjectSelectionScreenState();
}

class _ClassSubjectSelectionScreenState
    extends State<ClassSubjectSelectionScreen> {
  String? _selectedClass;
  String? _selectedSubject;
  final TextEditingController _textbookNameController = TextEditingController();

  // ✅ CORRECTED: Classes 1-10
  final List<String> _classes = [
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
  ];

  // ✅ CORRECTED: Only 4 subjects
  final List<String> _subjects = [
    'English',
    'Mathematics',
    'Science',
    'Social Studies',
  ];

  @override
  void dispose() {
    _textbookNameController.dispose();
    super.dispose();
  }

  void _proceed() {
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class')),
      );
      return;
    }

    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject')),
      );
      return;
    }

    if (_textbookNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter textbook name')),
      );
      return;
    }

    // Navigate to chapter list with metadata
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChapterListScreen(
          metadata: {
            'class': _selectedClass!,
            'subject': _selectedSubject!,
            'textbookName': _textbookNameController.text.trim(),
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Class & Subject'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.indigo, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Provide textbook information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This helps organize your content better',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // Class selection
            const Text(
              'Class *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedClass,
                  hint: const Text('Select Class'),
                  isExpanded: true,
                  items: _classes.map((String className) {
                    return DropdownMenuItem<String>(
                      value: className,
                      child: Row(
                        children: [
                          const Icon(Icons.school,
                              size: 20, color: Colors.indigo),
                          const SizedBox(width: 12),
                          Text(className),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedClass = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Subject selection
            const Text(
              'Subject *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubject,
                  hint: const Text('Select Subject'),
                  isExpanded: true,
                  items: _subjects.map((String subject) {
                    return DropdownMenuItem<String>(
                      value: subject,
                      child: Row(
                        children: [
                          Icon(
                            _getSubjectIcon(subject),
                            size: 20,
                            color: _getSubjectColor(subject),
                          ),
                          const SizedBox(width: 12),
                          Text(subject),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSubject = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Textbook name
            const Text(
              'Textbook Name *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textbookNameController,
              decoration: InputDecoration(
                hintText: 'e.g., NCERT Science',
                prefixIcon: const Icon(Icons.library_books),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // Preview card
            if (_selectedClass != null ||
                _selectedSubject != null ||
                _textbookNameController.text.isNotEmpty)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.preview, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Preview',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedClass != null)
                        _buildPreviewRow('Class', _selectedClass!),
                      if (_selectedSubject != null)
                        _buildPreviewRow('Subject', _selectedSubject!),
                      if (_textbookNameController.text.isNotEmpty)
                        _buildPreviewRow(
                            'Textbook', _textbookNameController.text),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Proceed button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _proceed,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Proceed to Upload Textbook'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case 'English':
        return Icons.book;
      case 'Mathematics':
        return Icons.calculate;
      case 'Science':
        return Icons.science;
      case 'Social Studies':
        return Icons.public;
      default:
        return Icons.book;
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'English':
        return Colors.blue;
      case 'Mathematics':
        return Colors.orange;
      case 'Science':
        return Colors.green;
      case 'Social Studies':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
