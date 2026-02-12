import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/providers/assessment_provider.dart';

class PaperGenScreen extends StatefulWidget {
  const PaperGenScreen({super.key});

  @override
  State<PaperGenScreen> createState() => _PaperGenScreenState();
}

class _PaperGenScreenState extends State<PaperGenScreen> {
  final Logger _logger = Logger();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _topicsController = TextEditingController();

  String _selectedTier = "Basic"; // Basic or Advanced
  bool _isGenerating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _topicsController.dispose();
    super.dispose();
  }

  Future<void> _generateExam(
      BuildContext context, AssessmentProvider provider) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_titleController.text.trim().isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Please enter exam title")),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final rawContent = args?['rawContent'] ?? '';
      final metadata = args?['metadata'] as Map<String, String>?;
      final extractedImages =
          args?['extractedImages'] as List<Map<String, dynamic>>?;

      await provider.generateExamWithTier(
        title: _titleController.text.trim(),
        difficulty: _selectedTier,
        topics: _topicsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        rawContent: rawContent,
        metadata: metadata,
        extractedImages: extractedImages,
      );

      if (!mounted) return;

      if (provider.error == null) {
        _logger.i("✅ $_selectedTier tier exam generated successfully");
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("$_selectedTier tier exam generated successfully"),
            backgroundColor: Colors.green,
          ),
        );

        navigator.pushNamed('/exam-preview');
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text("Error: ${provider.error}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Failed to generate exam: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Question Paper Generation (Module 6)"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          "Automatic Exam Papers",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "• Basic Tier: 25 questions, 35 marks, 90 min\n"
                      "• Advanced Tier: 23 questions, 50 marks, 120 min\n"
                      "• Fixed structure as per curriculum",
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Exam title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Exam Title",
                border: OutlineInputBorder(),
                hintText: "e.g., Class 6 Science - Mid Term",
              ),
            ),
            const SizedBox(height: 16),

            // Topics
            TextField(
              controller: _topicsController,
              decoration: const InputDecoration(
                labelText: "Topics (comma-separated)",
                border: OutlineInputBorder(),
                hintText: "e.g., Photosynthesis, Cell Structure, Digestion",
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Tier selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Tier",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // ✅ FIXED: Using RadioGroup with 'groupValue'
                    RadioGroup<String>(
                      groupValue:
                          _selectedTier, // Changed from value to groupValue
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() => _selectedTier = value);
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: "Basic",
                            // No groupValue or onChanged here
                            title: const Text("Basic Tier"),
                            subtitle: const Text(
                              "MCQ (10) + Fill-up (5) + True/False (5) + Short Ans (5×3)",
                            ),
                            activeColor: Colors.indigo,
                          ),
                          RadioListTile<String>(
                            value: "Advanced",
                            // No groupValue or onChanged here
                            title: const Text("Advanced Tier"),
                            subtitle: const Text(
                              "MCQ (8) + Fill-up (4) + OddOneOut (3) + Short (4×3) + Long (3×5) + Case Study (1×8)",
                            ),
                            activeColor: Colors.indigo,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Generate button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isGenerating
                    ? null
                    : () => _generateExam(context, provider),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.description),
                label: Text(
                  _isGenerating
                      ? "Generating $_selectedTier Tier..."
                      : "Generate $_selectedTier Tier Exam",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
              ),
            ),

            if (_isGenerating)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      provider.currentStatus.isNotEmpty
                          ? provider.currentStatus
                          : "Generating questions... This may take 1-2 minutes.",
                      textAlign: TextAlign.center,
                    ),
                    if (provider.totalQuestions > 0) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: provider.generationProgress,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${provider.questionsGenerated} / ${provider.totalQuestions} questions",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
