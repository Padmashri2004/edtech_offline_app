import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/providers/assessment_provider.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  @override
  void initState() {
    super.initState();
    // FIXED: Check mounted to avoid BuildContext async gap warning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AssessmentProvider>().loadAllAssessments();
      }
    });
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _deleteAssessment(int assessmentId, String type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Assessment?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context
          .read<AssessmentProvider>()
          .deleteAssessment(assessmentId, type);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Dashboard (Member 1)"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AssessmentProvider>().loadAllAssessments();
            },
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Consumer<AssessmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Error: ${provider.error}"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadAllAssessments(),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Module Cards
                Row(
                  children: [
                    Expanded(
                      child: _ModuleCard(
                        icon: Icons.quiz,
                        title: "Module 1",
                        subtitle: "Quiz Generation",
                        color: Colors.blue,
                        count: provider.quizzes.length,
                        onTap: () =>
                            Navigator.pushNamed(context, '/chapter-list'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ModuleCard(
                        icon: Icons.description,
                        title: "Module 6",
                        subtitle: "Exam Papers",
                        color: Colors.green,
                        count: provider.exams.length,
                        onTap: () =>
                            Navigator.pushNamed(context, '/chapter-list'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Recent Quizzes
                _buildSection(
                  title: "Recent Quizzes",
                  count: provider.quizzes.length,
                  items: provider.quizzes.take(5).toList(),
                  type: 'quiz',
                ),

                const SizedBox(height: 24),

                // Recent Exams
                _buildSection(
                  title: "Recent Exam Papers",
                  count: provider.exams.length,
                  items: provider.exams.take(5).toList(),
                  type: 'exam',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required int count,
    required List<ExamModel> items,
    required String type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (count > 0)
              Text(
                "$count total",
                style: TextStyle(color: Colors.grey.shade600),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      type == 'quiz'
                          ? Icons.quiz_outlined
                          : Icons.description_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No ${type}es created yet",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/chapter-list'),
                      icon: const Icon(Icons.add),
                      label: Text(
                          "Create ${type == 'quiz' ? 'Quiz' : 'Exam Paper'}"),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...items.map((item) => _buildAssessmentCard(item, type)),
      ],
    );
  }

  Widget _buildAssessmentCard(ExamModel assessment, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  type == 'quiz' ? Icons.quiz : Icons.description,
                  color: type == 'quiz' ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessment.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${assessment.difficulty} • ${_formatDate(assessment.timestamp)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    if (assessment.id != null) {
                      _deleteAssessment(assessment.id!, type);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.format_list_numbered,
                  label: "${assessment.questions.length} Questions",
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  icon: Icons.timer,
                  label: "${assessment.timerMinutes} min",
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  icon: Icons.star,
                  label: "${assessment.totalMarks} marks",
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      backgroundColor: Colors.grey.shade100,
      padding: EdgeInsets.zero,
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(
                      alpha:
                          0.1), // FIXED: Use withValues instead of withOpacity
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$count created",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
