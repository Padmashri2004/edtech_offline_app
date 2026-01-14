import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle
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
  // Stores selected topics: { "Chapter Title": ["Topic 1", "Topic 2"] }
  final Map<String, List<String>> _selectedTopics = {};
  bool _isLoading = false;

  /// Trigger the File Picker
  Future<void> _handlePickFile() async {
    setState(() => _isLoading = true);
    final file = await _pdfService.pickTextbook();

    if (file != null) {
      // 1. Get basic chapters from PDF Bookmarks
      final pdfChapters = await _pdfService.getChapters(file);

      // 2. Try to merge with Manifest topics (simulated logic for the project)
      // In a real app, you would parse the actual JSON file here.
      final mergedChapters = await _mergeWithManifest(pdfChapters, file.path);

      setState(() {
        _selectedFile = file;
        _chapters = mergedChapters;
        _isLoading = false;
        _selectedTopics.clear();
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  /// Helper to merge PDF bookmarks with "Topics" from your JSON manifest
  Future<List<Map<String, dynamic>>> _mergeWithManifest(
      List<Map<String, dynamic>> chapters, String filePath) async {
    // This mocks loading the 'textbook_manifest.json' you provided.
    // In production, load the actual file using File(path).readAsString().
    try {
      final jsonString = await rootBundle
          .loadString('assets/textbooks/textbook_manifest.json');
      final Map<String, dynamic> manifest = jsonDecode(jsonString);
      final List<dynamic> books = manifest['textbooks'];

      // Find matching book by filename (simple check)
      final matchingBook = books.firstWhere(
          (b) => filePath.contains(b['fileName']),
          orElse: () => null);

      if (matchingBook != null) {
        final List<dynamic> manifestChapters = matchingBook['chapters'];
        for (var chapter in chapters) {
          final match = manifestChapters.firstWhere(
              (c) =>
                  c['chapterNumber'].toString() ==
                  chapter['title'].split(' ').last,
              orElse: () => null);
          if (match != null) {
            chapter['topics'] = List<String>.from(match['topics']);
          } else {
            // Fallback default topics if not in JSON
            chapter['topics'] = ["Introduction", "Key Concepts", "Summary"];
          }
        }
      }
    } catch (e) {
      debugPrint("Manifest load error (using defaults): $e");
      // Add default topics so the UI still works
      for (var c in chapters) {
        c['topics'] = ["General Concept", "Detailed Analysis", "Examples"];
      }
    }
    return chapters;
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

  void _navigateToQuizGen(Map<String, dynamic> chapter) {
    // If no specific topics selected, send them all (or empty to imply 'All')
    final topics = _selectedTopics[chapter['title']] ?? [];

    Navigator.pushNamed(context, '/quiz-gen', arguments: {
      'file': _selectedFile,
      'title': chapter['title'],
      'startPage': chapter['startPage'],
      'endPage': chapter['endPage'],
      'topics': topics.isEmpty ? chapter['topics'] : topics,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Textbook Content")),
      body: Column(
        children: [
          // Top Section: File Selection
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handlePickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_selectedFile == null
                    ? "Upload Textbook (PDF)"
                    : "Change: ${_selectedFile!.path.split('/').last}"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // Bottom Section: Chapter & Topic List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _chapters.isEmpty
                    ? const Center(
                        child: Text(
                            "No content loaded.\nPlease upload a textbook.",
                            textAlign: TextAlign.center))
                    : ListView.builder(
                        itemCount: _chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _chapters[index];
                          final title = chapter['title'] as String;
                          final topics = (chapter['topics'] as List<dynamic>?)
                                  ?.map((e) => e.toString())
                                  .toList() ??
                              [];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: ExpansionTile(
                              leading:
                                  CircleAvatar(child: Text("${index + 1}")),
                              title: Text(title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  "Pages: ${chapter['startPage']} - ${chapter['endPage']}"),
                              children: [
                                ...topics.map((topic) {
                                  final isSelected =
                                      _selectedTopics[title]?.contains(topic) ??
                                          false;
                                  return CheckboxListTile(
                                    title: Text(topic),
                                    value: isSelected,
                                    dense: true,
                                    onChanged: (val) =>
                                        _toggleTopic(title, topic),
                                  );
                                }),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _navigateToQuizGen(chapter),
                                    child: const Text(
                                        "Generate Quiz from Selection"),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
