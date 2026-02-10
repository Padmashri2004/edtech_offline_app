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

  // FIXED: Only tier selection needed (100 marks is automatic)
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
    // Capture ScaffoldMessenger before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // Capture Navigator before async gap
    final navigator = Navigator.of(context);

    if (_titleController.text.trim().isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Please enter exam title")),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // FIXED: Call with tier, topics, and raw content
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final rawContent = args?['rawContent'] ?? '';

      await provider.generateExamWithTier(
        title: _titleController.text.trim(),
        difficulty: _selectedTier,
        topics: _topicsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        rawContent: rawContent,
      );

      if (!mounted) return;

      if (provider.error == null) {
        _logger.i("✅ $_selectedTier tier exam generated successfully");
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content: Text("$_selectedTier tier exam generated (100 marks)")),
        );
        navigator.pop();
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          "Automatic 100 Marks Papers",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "• Basic Tier: Section A (20) + B (15) + C (35) + D (30) = 100\n"
                      "• Advanced Tier: Section A (20) + B (25) + C (5) + D (50) = 100\n"
                      "• Fixed structure as per government curriculum",
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

            // Tier selection (RadioGroup API)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Tier (100 marks automatic)",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    RadioGroup<String>(
                      groupValue: _selectedTier,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedTier = val);
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: "Basic",
                            title: const Text("Basic Tier"),
                            subtitle: const Text(
                              "MCQ (5) + Fill-up (5) + Odd One Out (5) + Rearrange (5)\n"
                              "+ Match It (5×3) + Short Ans (7×5) + Long Ans (3×10)",
                            ),
                          ),
                          RadioListTile<String>(
                            value: "Advanced",
                            title: const Text("Advanced Tier"),
                            subtitle: const Text(
                              "MCQ (5) + Fill-up (5) + True/False (5) + Odd One Out (5)\n"
                              "+ Short Ans (5×5) + Case Study (1×5) + Long Ans (5×10)",
                            ),
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.description),
                label: Text(_isGenerating
                    ? "Generating $_selectedTier Tier..."
                    : "Generate $_selectedTier Tier Exam (100 marks)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
              ),
            ),

            if (_isGenerating)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        "Generating questions... This may take 1-2 minutes.",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
