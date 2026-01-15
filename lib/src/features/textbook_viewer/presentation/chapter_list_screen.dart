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
  bool _isAnalyzingSubtopics = false;

  // Track selected chapter index
  final Set<int> _checkedChaptersIndices = {};
  final Set<int> _analyzedChaptersIndices = {};
  final Map<String, List<String>> _selectedTopics = {};

  Future<void> _handlePickFile() async {
    setState(() => _isLoading = true);
    final file = await _pdfService.pickTextbook(); //
    if (file != null) {
      final scannedChapters = await _pdfService.getChapters(file); //
      setState(() {
        _selectedFile = file;
        _chapters = scannedChapters;
        _isLoading = false;
        _selectedTopics.clear();
        _checkedChaptersIndices.clear();
        _analyzedChaptersIndices.clear();
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeSelectedChapters() async {
    if (_checkedChaptersIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select at least one chapter to analyze.")));
      return;
    }
    setState(() => _isAnalyzingSubtopics = true);

    // Scan subtopics for selected chapters
    for (int index in _checkedChaptersIndices) {
      if (_analyzedChaptersIndices.contains(index)) continue;
      var chapter = _chapters[index];
      List<String> subtopics = await _pdfService.scanChapterSubtopics(
          _selectedFile!, chapter['startPage'], chapter['endPage']); //
      setState(() {
        _chapters[index]['topics'] = subtopics;
        _analyzedChaptersIndices.add(index);
      });
    }
    setState(() => _isAnalyzingSubtopics = false);
  }

  void _toggleTopic(String chapterTitle, String topic) {
    setState(() {
      if (!_selectedTopics.containsKey(chapterTitle)) {
        _selectedTopics[chapterTitle] = [];
      }
      if (_selectedTopics[chapterTitle]!.contains(topic)) {
        _selectedTopics[chapterTitle]!.remove(topic);
      } else {
        _selectedTopics[chapterTitle]!.add(topic);
      }
    });
  }

  // --- CRITICAL FIX: Dual Navigation Logic ---
  void _navigateToModule(String routeName) {
    if (_checkedChaptersIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select a chapter first.")));
      return;
    }

    // Get the first selected chapter for processing
    int firstIndex = _checkedChaptersIndices.first;
    var chapter = _chapters[firstIndex];

    Navigator.pushNamed(context, routeName, arguments: {
      'file': _selectedFile,
      'title': chapter['title'],
      'startPage': chapter['startPage'],
      'endPage': chapter['endPage'],
      // Pass full selection if needed for advanced logic
      'selection': _selectedTopics,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Content")),
      body: Column(
        children: [
          // 1. Upload Button
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

          // 2. Chapter List Header
          if (_chapters.isNotEmpty)
            Container(
              color: Colors.indigo.shade50,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${_checkedChaptersIndices.length} Chapters Selected",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                      onPressed: _isAnalyzingSubtopics
                          ? null
                          : _analyzeSelectedChapters,
                      child: _isAnalyzingSubtopics
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Scan for Topics"))
                ],
              ),
            ),

          // 3. Chapter List View
          Expanded(
            child: _chapters.isEmpty
                ? const Center(child: Text("Upload a textbook to begin."))
                : ListView.builder(
                    itemCount: _chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = _chapters[index];
                      final title = chapter['title'];
                      final isAnalyzed =
                          _analyzedChaptersIndices.contains(index);
                      List<String> topics = isAnalyzed
                          ? List<String>.from(chapter['topics'] ?? [])
                          : [];

                      return Card(
                        child: Column(
                          children: [
                            CheckboxListTile(
                              title: Text(title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  "Pages ${chapter['startPage']} - ${chapter['endPage']}"),
                              value: _checkedChaptersIndices.contains(index),
                              secondary: CircleAvatar(
                                backgroundColor:
                                    isAnalyzed ? Colors.green : Colors.grey,
                                child: Icon(
                                    isAnalyzed ? Icons.check : Icons.search,
                                    color: Colors.white),
                              ),
                              onChanged: (bool? val) {
                                setState(() {
                                  // Single selection logic for simplicity in MVP
                                  _checkedChaptersIndices.clear();
                                  if (val == true) {
                                    _checkedChaptersIndices.add(index);
                                  }
                                });
                              },
                            ),
                            if (isAnalyzed)
                              ExpansionTile(
                                title: const Text("Select Subtopics",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                initiallyExpanded: true,
                                children: topics.map((topic) {
                                  final isSelected =
                                      _selectedTopics[title]?.contains(topic) ??
                                          false;
                                  return CheckboxListTile(
                                    dense: true,
                                    title: Text(topic),
                                    value: isSelected,
                                    onChanged: (val) =>
                                        _toggleTopic(title, topic),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 4. Action Buttons (FIXED)
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
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
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
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
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
