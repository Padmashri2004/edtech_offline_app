import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/providers/assessment_provider.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/pdf_export_service.dart';

class ExamPreviewScreen extends StatefulWidget {
  const ExamPreviewScreen({super.key});

  @override
  State<ExamPreviewScreen> createState() => _ExamPreviewScreenState();
}

class _ExamPreviewScreenState extends State<ExamPreviewScreen> {
  bool _isGeneratingPDF = false;

  Map<String, List<QuestionModel>> _groupBySection(ExamModel exam) {
    final Map<String, List<QuestionModel>> sections = {
      'Section A': [],
      'Section B': [],
      'Section C': [],
      'Section D': [],
    };

    // Group questions by section based on type
    for (var question in exam.questions) {
      if (question.type == 'MCQ' ||
          question.type == 'Fill-up' ||
          question.type == 'True/False' ||
          question.type == 'OddOneOut') {
        sections['Section A']!.add(question);
      } else if (question.type == 'Match' || question.type == 'MatchIt') {
        sections['Section B']!.add(question);
      } else if (question.type == 'ShortAns') {
        sections['Section C']!.add(question);
      } else if (question.type == 'LongAns' || question.type == 'CaseStudy') {
        sections['Section D']!.add(question);
      }
    }

    // Remove empty sections
    sections.removeWhere((key, value) => value.isEmpty);
    return sections;
  }

  int _calculateSectionMarks(List<QuestionModel> questions) {
    return questions.fold(0, (sum, q) => sum + q.marks);
  }

  Future<void> _downloadPDF(ExamModel exam) async {
    setState(() => _isGeneratingPDF = true);

    final pdfService = context.read<PDFExportService>();
    final pdfPath = await pdfService.exportExamToPDF(exam);

    setState(() => _isGeneratingPDF = false);

    if (mounted) {
      if (pdfPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF saved: ${pdfPath.split('/').last}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to generate PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AssessmentProvider>();
    final exam = provider.currentAssessment;

    if (exam == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Exam Preview'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No exam generated'),
        ),
      );
    }

    final sections = _groupBySection(exam);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Paper Preview'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to quiz preview for editing
              Navigator.pushNamed(context, '/quiz-preview');
            },
            tooltip: 'Edit Questions',
          ),
        ],
      ),
      body: Column(
        children: [
          // Exam info card
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description,
                          size: 32, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${exam.difficulty} Tier Examination',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoChip(
                        icon: Icons.star,
                        label: '${exam.totalMarks} marks',
                        color: Colors.orange,
                      ),
                      _InfoChip(
                        icon: Icons.timer,
                        label: '${exam.timerMinutes} min',
                        color: Colors.blue,
                      ),
                      _InfoChip(
                        icon: Icons.format_list_numbered,
                        label: '${exam.questions.length} questions',
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Preview label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.visibility, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  'Question Paper Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Scrollable preview
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Center(
                      child: Text(
                        'GOVERNMENT SCHOOL EXAMINATION',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        exam.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Student info fields
                    const Text('Class: ___________  Roll No: ___________'),
                    const SizedBox(height: 4),
                    const Text('Date: ___________   Subject: ___________'),
                    const SizedBox(height: 4),
                    Text(
                        'Total Marks: ${exam.totalMarks}  Time: ${exam.timerMinutes} minutes'),

                    const Divider(height: 32),

                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INSTRUCTIONS:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text('• All questions are compulsory'),
                          Text('• Write answers in the space provided'),
                          Text('• Marks are indicated against each question'),
                          Text('• Read questions carefully before answering'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sections
                    ...sections.entries.map((entry) {
                      final sectionName = entry.key;
                      final questions = entry.value;
                      final sectionMarks = _calculateSectionMarks(questions);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$sectionName ($sectionMarks marks)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Questions in this section
                          ...questions.asMap().entries.map((qEntry) {
                            // Calculate global question number
                            int globalNumber = 1;
                            for (var prevSection in sections.entries) {
                              if (prevSection.key == sectionName) {
                                globalNumber += qEntry.key;
                                break;
                              }
                              globalNumber += prevSection.value.length;
                            }

                            return _buildQuestionPreview(
                              globalNumber,
                              qEntry.value,
                            );
                          }),

                          const SizedBox(height: 24),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isGeneratingPDF
                        ? null
                        : () => Navigator.pushNamed(context, '/quiz-preview'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Questions'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isGeneratingPDF ? null : () => _downloadPDF(exam),
                    icon: _isGeneratingPDF
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                        _isGeneratingPDF ? 'Generating...' : 'Download PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPreview(int number, QuestionModel question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text with marks
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: '$number. ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: question.questionText),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '[${question.marks} ${question.marks == 1 ? "mark" : "marks"}]',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Options for MCQ/True-False/OddOneOut
          if (question.options.isNotEmpty &&
              (question.type == 'MCQ' ||
                  question.type == 'True/False' ||
                  question.type == 'OddOneOut')) ...[
            ...question.options.asMap().entries.map((entry) {
              final letter = String.fromCharCode(97 + entry.key); // a, b, c, d
              return Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 4),
                child: Text('($letter) ${entry.value}'),
              );
            }),
          ],

          // Answer space for fill-up/short/long
          if (question.type == 'Fill-up' ||
              question.type == 'ShortAns' ||
              question.type == 'LongAns' ||
              question.type == 'CaseStudy') ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Answer:',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 4),
                  ...List.generate(
                    question.type == 'LongAns' || question.type == 'CaseStudy'
                        ? 8
                        : 3,
                    (i) => Text('_' * 60),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
