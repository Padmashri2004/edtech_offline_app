import 'dart:io';
import 'package:flutter/material.dart';
// Using package import to avoid ../../../ paths
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

  /// Trigger the File Picker
  Future<void> _handlePickFile() async {
    setState(() => _isLoading = true);
    final file = await _pdfService.pickTextbook();
    
    if (file != null) {
      final chapters = await _pdfService.getChapters(file);
      setState(() {
        _selectedFile = file;
        _chapters = chapters;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Textbook & Chapters")),
      body: Column(
        children: [
          // Top Section: File Selection
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _handlePickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(_selectedFile == null ? "Select PDF Textbook" : "Change Textbook"),
            ),
          ),
          
          if (_selectedFile != null) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("File: ${_selectedFile!.path.split('/').last}", 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ),

          const Divider(),

          // Bottom Section: Chapter List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _chapters.isEmpty 
                ? const Center(child: Text("No chapters found. Please select a PDF."))
                : ListView.builder(
                    itemCount: _chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = _chapters[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text("${index + 1}")),
                        title: Text(chapter['title']),
                        subtitle: Text("Pages: ${chapter['startPage']} - ${chapter['endPage']}"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Pass selected chapter data to the Quiz Generator
                          Navigator.pushNamed(
                            context, 
                            '/quiz-gen', 
                            arguments: {
                              'file': _selectedFile,
                              'title': chapter['title'],
                              'startPage': chapter['startPage'],
                              'endPage': chapter['endPage'],
                            }
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}