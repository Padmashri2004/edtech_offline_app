import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_offline_app/services/pdf_service.dart';
import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';

class QuizGenScreen extends StatefulWidget {
  const QuizGenScreen({super.key});

  @override
  State<QuizGenScreen> createState() => _QuizGenScreenState();
}

class _QuizGenScreenState extends State<QuizGenScreen> {
  final PdfService _pdfService = PdfService();
  String _extractedText = "";
  bool _isExtracting = true; // Used for both text extraction and AI generation loading state
  String _chapterTitle = "";
  
  // To store generated questions temporarily for display (Prototype)
  List<Map<String, dynamic>> _generatedQuestions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 1. Get the arguments passed from the Chapter List Screen
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      _chapterTitle = args['title'];
      _startExtraction(
        args['file'] as File,
        args['startPage'] as int,
        args['endPage'] as int
      );
    }
  }

  /// 2. Extract text only from the requested range
  Future<void> _startExtraction(File file, int start, int end) async {
    try {
      final text = await _pdfService.extractChapterText(file, start, end);
      if (mounted) {
        setState(() {
          _extractedText = text;
          _isExtracting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExtracting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Extraction Error: $e")),
        );
      }
    }
  }

  /// 3. Call the AI Service to generate questions
  Future<void> _handleGenerate() async {
    if (_extractedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No text to generate from!")),
      );
      return;
    }

    setState(() => _isExtracting = true); // Reuse loading state

    try {
      // Access the repository via Provider
      final aiRepo = context.read<AIRepository>();
      
      // Call AI Logic
      final quizData = await aiRepo.getQuizFromChapter(
        rawContent: _extractedText,
        difficulty: 'Basic', // Hardcoded for prototype, can be a Dropdown later
      );

      if (mounted) {
        setState(() {
          _isExtracting = false;
          _generatedQuestions = quizData;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Success! Generated ${quizData.length} questions.")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExtracting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("AI Error: $e")),
        );
      }
    }
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
                  Text("Processing content with AI..."),
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
                  
                  // Preview of Extracted Text
                  Expanded(
                    flex: 1,
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
                  
                  // Preview of Generated Questions (if any)
                  if (_generatedQuestions.isNotEmpty) ...[
                    const Text(
                      "Generated Questions Preview:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      flex: 2,
                      child: ListView.builder(
                        itemCount: _generatedQuestions.length,
                        itemBuilder: (context, index) {
                          final q = _generatedQuestions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(child: Text("${index + 1}")),
                              title: Text(q['question'] ?? "No text"),
                              subtitle: Text("Answer: ${q['options']?[q['answer_index']]}"),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.psychology),
                      onPressed: _handleGenerate,
                      label: const Text("Generate Questions with AI"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}