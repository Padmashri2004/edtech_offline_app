import 'dart:io';
import 'package:flutter/material.dart';
import 'package:edtech_offline_app/services/pdf_service.dart';
import 'package:edtech_offline_app/services/image_extraction_service.dart';

class ChapterListScreen extends StatefulWidget {
  final Map<String, String>? metadata;

  const ChapterListScreen({super.key, this.metadata});

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  final PdfService _pdfService = PdfService();
  final ImageExtractionService _imageService = ImageExtractionService();

  File? _selectedFile;
  List<Map<String, dynamic>> _chapters = [];
  List<Map<String, dynamic>> _extractedImages = [];
  bool _isLoading = false;
  final Set<int> _checkedChaptersIndices = {};
  bool _selectAll = false;
  bool _tocDetected = false;

  Future<void> _handlePickFile() async {
    setState(() => _isLoading = true);
    final file = await _pdfService.pickTextbook();

    if (file != null) {
      final chapters = await _pdfService.getChapters(file);

      setState(() {
        _selectedFile = file;
        _chapters = chapters;
        _tocDetected = chapters.isNotEmpty; // simple heuristic
        _isLoading = false;
        _checkedChaptersIndices.clear();
        _selectAll = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
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

  Future<void> _extractImagesFromSelectedChapters() async {
    if (_selectedFile == null || _checkedChaptersIndices.isEmpty) return;

    setState(() => _isLoading = true);
    _extractedImages.clear();

    for (int index in _checkedChaptersIndices) {
      final chapter = _chapters[index];

      final images = await _imageService.extractImagesWithCaptions(
        _selectedFile!,
        chapter['startPage'],
        chapter['endPage'],
      );

      _extractedImages.addAll(images);
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (_extractedImages.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('✅ Extracted ${_extractedImages.length} images')),
      );
    }
  }

  Future<void> _navigateToModule(String routeName) async {
    if (_checkedChaptersIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a chapter first.")),
      );
      return;
    }
    if (_selectedFile == null) return;

    if (_extractedImages.isEmpty) {
      await _extractImagesFromSelectedChapters();
    }

    final firstIndex = _checkedChaptersIndices.first;
    final chapter = _chapters[firstIndex];
    setState(() => _isLoading = true);

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
      'metadata': widget.metadata,
      'extractedImages': _extractedImages,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Content"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (widget.metadata != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.metadata!['class']} • ${widget.metadata!['subject']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.metadata!['textbookName'] ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handlePickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(
                    _selectedFile == null ? "Upload Textbook" : "Change Book"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          if (_chapters.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _tocDetected ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _tocDetected ? Colors.green : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _tocDetected ? Icons.check_circle : Icons.warning,
                    color: _tocDetected ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _tocDetected
                          ? '✓ Chapters detected'
                          : '⚠ Using fallback chapter detection',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _tocDetected
                            ? Colors.green.shade900
                            : Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                  const Text("Select All"),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed:
                        _isLoading ? null : _extractImagesFromSelectedChapters,
                    icon: const Icon(Icons.image),
                    label: Text(_extractedImages.isEmpty
                        ? 'Extract Images'
                        : '${_extractedImages.length} Images'),
                  ),
                ],
              ),
            ),
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
                    label: const Text("Mod 6: Exam"),
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
