// lib/src/features/quiz_exam_gen/presentation/history_screen.dart
// ✅ Fully safe: no BuildContext across async gaps, no deprecated warnings

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/providers/assessment_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _filterClass;
  String? _filterSubject;
  String? _filterType;

  final List<String> _classes = [
    'All',
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
  ];

  final List<String> _subjects = [
    'All',
    'English',
    'Mathematics',
    'Science',
    'Social Studies',
  ];

  final List<String> _types = [
    'All',
    'Quiz',
    'Exam',
  ];

  @override
  void initState() {
    super.initState();
    _filterClass = 'All';
    _filterSubject = 'All';
    _filterType = 'All';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AssessmentProvider>().loadAllAssessments();
    });
  }

  List<ExamModel> _getFilteredAssessments(List<ExamModel> allAssessments) {
    return allAssessments.where((assessment) {
      if (_filterClass != 'All' &&
          assessment.metadata?['class'] != _filterClass) {
        return false;
      }
      if (_filterSubject != 'All' &&
          assessment.metadata?['subject'] != _filterSubject) {
        return false;
      }
      if (_filterType != 'All') {
        final typeMatch = _filterType == 'Quiz'
            ? assessment.type == 'quiz'
            : assessment.type == 'exam';
        if (!typeMatch) return false;
      }
      return true;
    }).toList();
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _deleteAssessment(ExamModel assessment) async {
    // Capture everything needed BEFORE async gaps
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<AssessmentProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Delete "${assessment.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await provider.deleteAssessment(assessment.id!);

    if (!mounted) return;

    messenger
        .showSnackBar(const SnackBar(content: Text('Deleted successfully')));
  }

  Future<void> _togglePublish(ExamModel assessment) async {
    final provider = context.read<AssessmentProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final updated = assessment.copyWith(published: !assessment.published);
    await provider.saveAssessment(updated);

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(updated.published
            ? 'Published successfully'
            : 'Unpublished successfully'),
      ),
    );
  }

  void _openPreview(ExamModel assessment) {
    if (!mounted) return;
    final provider = context.read<AssessmentProvider>();
    provider.setCurrentAssessment(assessment);

    if (assessment.type == 'quiz') {
      Navigator.pushNamed(context, '/quiz-preview');
    } else {
      Navigator.pushNamed(context, '/exam-preview');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _filterClass,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _classes
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (value) {
                          if (!mounted) return;
                          setState(() => _filterClass = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _filterSubject,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _subjects
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (value) {
                          if (!mounted) return;
                          setState(() => _filterSubject = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _filterType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) {
                    if (!mounted) return;
                    setState(() => _filterType = value);
                  },
                ),
              ],
            ),
          ),
          // List of assessments
          Expanded(
            child: Consumer<AssessmentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allAssessments = [
                  ...provider.quizzes,
                  ...provider.exams,
                ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                final filtered = _getFilteredAssessments(allAssessments);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 20),
                        const Text(
                          'No items found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try changing filters',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final assessment = filtered[index];
                    final isQuiz = assessment.type == 'quiz';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isQuiz
                              ? Colors.blue.shade100
                              : Colors.green.shade100,
                          child: Icon(
                            isQuiz ? Icons.quiz : Icons.description,
                            color: isQuiz ? Colors.blue : Colors.green,
                          ),
                        ),
                        title: Text(
                          assessment.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                                '${assessment.metadata?['class'] ?? 'N/A'} • ${assessment.metadata?['subject'] ?? 'N/A'}'),
                            Text(
                                '${assessment.questions.length} questions • ${assessment.totalMarks} marks'),
                            Text(
                              'Created: ${_formatDate(assessment.timestamp)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  assessment.published
                                      ? Icons.check_circle
                                      : Icons.edit_note,
                                  size: 16,
                                  color: assessment.published
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  assessment.published ? 'Published' : 'Draft',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: assessment.published
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, size: 20),
                                  SizedBox(width: 8),
                                  Text('View/Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'republish',
                              child: Row(
                                children: [
                                  Icon(
                                    assessment.published
                                        ? Icons.unpublished
                                        : Icons.publish,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(assessment.published
                                      ? 'Unpublish'
                                      : 'Publish'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            switch (value) {
                              case 'view':
                                _openPreview(assessment);
                                break;
                              case 'republish':
                                await _togglePublish(assessment);
                                break;
                              case 'delete':
                                await _deleteAssessment(assessment);
                                break;
                            }
                          },
                        ),
                        onTap: () => _openPreview(assessment),
                      ),
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
