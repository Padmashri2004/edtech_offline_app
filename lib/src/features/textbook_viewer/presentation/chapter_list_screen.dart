import 'dart:io';
import 'package:flutter/material.dart';
import 'package:edtech_offline_app/services/pdf_service.dart';

class ChapterListScreen extends StatefulWidget {
  const ChapterListScreen({super.key});

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  final PdfService _pdfService = PdfService();
  File? _selectedFile;
  List<Map<String, dynamic>> _chapters = [];
  bool _isLoading = false;
  final Set<int> _checkedChaptersIndices = {};
  bool _selectAll = false;

  // ✅ Progress tracking
  double extractionProgress = 0.0;
  bool _isExtracting = false;
  String? _currentChapterTitle; // show which chapter is being processed

  Future<void> _handlePickFile() async {
    setState(() => _isLoading = true);
    final file = await _pdfService.pickTextbook();
    if (file != null) {
      final scannedChapters = await _pdfService.getChapters(file);
      setState(() {
        _selectedFile = file;
        _chapters = scannedChapters;
        _isLoading = false;
        _checkedChaptersIndices.clear();
        extractionProgress = 0.0;
        _selectAll = false;
        _currentChapterTitle = null;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _extractSelectedChapters() async {
    if (_checkedChaptersIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one chapter.")),
      );
      return;
    }

    setState(() {
      _isExtracting = true;
      extractionProgress = 0.0;
      _currentChapterTitle = null;
    });

    int total = _checkedChaptersIndices.length;
    int processed = 0;

    // ✅ Use index to show which chapter is being processed
    for (int index in _checkedChaptersIndices) {
      final chapter = _chapters[index];
      _currentChapterTitle = chapter['title'];
      await Future.delayed(const Duration(milliseconds: 400)); // simulate work
      processed++;
      setState(() {
        extractionProgress = processed / total;
      });
    }

    setState(() {
      _isExtracting = false;
      _currentChapterTitle = null;
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      _checkedChaptersIndices.clear();
      if (_selectAll) {
        for (int i = 0; i < _chapters.length; i++) {
          _checkedChaptersIndices.add(i);
        }
      }
    });
  }

  // FIXED: Extract chapter text and pass to navigation
  Future<void> _navigateToModule(String routeName) async {
    if (_checkedChaptersIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a chapter first.")),
      );
      return;
    }

    if (_selectedFile == null) return;

    // Extract text from first selected chapter
    final firstIndex = _checkedChaptersIndices.first;
    final chapter = _chapters[firstIndex];

    setState(() => _isLoading = true);

    // Extract chapter content
    final rawContent = await _pdfService.extractChapterText(
      _selectedFile!,
      chapter['startPage'],
      chapter['endPage'],
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    Navigator.pushNamed(context, routeName, arguments: {
      'file': _selectedFile,
      'chapter': chapter,
      'rawContent': rawContent,
      'selection': _checkedChaptersIndices.toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Content")),
      body: Column(
        children: [
          // Upload Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handlePickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(
                    _selectedFile == null ? "Upload Textbook" : "Change Book"),
              ),
            ),
          ),

          if (_isLoading) const LinearProgressIndicator(),

          // Header with Select All
          if (_chapters.isNotEmpty)
            Container(
              color: Colors.indigo.shade50,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectAll,
                    onChanged: _toggleSelectAll,
                  ),
                  const Text("Select All / Deselect All"),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isExtracting ? null : _extractSelectedChapters,
                    child: _isExtracting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("Extract Chapters"),
                  ),
                ],
              ),
            ),

          // Progress bar for extraction
          if (_isExtracting || extractionProgress > 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  LinearProgressIndicator(value: extractionProgress),
                  if (_currentChapterTitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text("Processing: $_currentChapterTitle"),
                    ),
                ],
              ),
            ),

          // Chapter List
          Expanded(
            child: _chapters.isEmpty
                ? const Center(child: Text("Upload a textbook to begin."))
                : ListView.builder(
                    itemCount: _chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = _chapters[index];
                      final title = chapter['title'];
                      return Card(
                        child: CheckboxListTile(
                          title: Text(title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              "Pages ${chapter['startPage']} - ${chapter['endPage']}"),
                          value: _checkedChaptersIndices.contains(index),
                          onChanged: (bool? val) {
                            setState(() {
                              if (val == true) {
                                _checkedChaptersIndices.add(index);
                              } else {
                                _checkedChaptersIndices.remove(index);
                              }
                              _selectAll = _checkedChaptersIndices.length ==
                                  _chapters.length;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectedFile != null
                        ? () => _navigateToModule('/quiz-gen')
                        : null,
                    icon: const Icon(Icons.flash_on),
                    label: const Text("Mod 1: Quiz"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedFile != null
                        ? () => _navigateToModule('/paper-gen')
                        : null,
                    icon: const Icon(Icons.description),
                    label: const Text("Mod 6: Exam Paper"),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
