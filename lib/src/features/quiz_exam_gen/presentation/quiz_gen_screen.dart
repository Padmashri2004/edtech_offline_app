import 'dart:io';
import 'package:flutter/material.dart';
// Exact package import as requested
import 'package:edtech_offline_app/services/pdf_service.dart';

class QuizGenScreen extends StatefulWidget {
  const QuizGenScreen({super.key});

  @override
  State<QuizGenScreen> createState() => _QuizGenScreenState();
}

class _QuizGenScreenState extends State<QuizGenScreen> {
  final PdfService _pdfService = PdfService();
  String _extractedText = "";
  bool _isExtracting = true;
  String _chapterTitle = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 1. Get the arguments passed from the Chapter List Screen
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    
    _chapterTitle = args['title'];
    _startExtraction(
      args['file'] as File, 
      args['startPage'] as int, 
      args['endPage'] as int
    );
  }

  /// 2. Extract text only from the requested range
  Future<void> _startExtraction(File file, int start, int end) async {
    final text = await _pdfService.extractChapterText(file, start, end);
    setState(() {
      _extractedText = text;
      _isExtracting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Generate: $_chapterTitle")),
      body: _isExtracting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Scanning textbook pages..."),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Extracted Content from $_chapterTitle",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // 3. Show a preview of the text that will go to the AI
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(_extractedText.isEmpty 
                            ? "No text found in this section." 
                            : _extractedText),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 4. Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("AI Question Generation coming next!")),
                        );
                      },
                      child: const Text("Generate Questions with AI"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}