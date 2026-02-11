import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/presentation/providers/assessment_provider.dart';

class StudentQuizListScreen extends StatefulWidget {
  const StudentQuizListScreen({super.key});

  @override
  State<StudentQuizListScreen> createState() => _StudentQuizListScreenState();
}

class _StudentQuizListScreenState extends State<StudentQuizListScreen> {
  @override
  void initState() {
    super.initState();
    // FIXED: Check mounted to avoid BuildContext async gap warning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AssessmentProvider>().loadQuizzes();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Quizzes"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AssessmentProvider>().loadQuizzes();
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
                    onPressed: () => provider.loadQuizzes(),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          // ✅ FILTER: Show only published quizzes to students
          final publishedQuizzes =
              provider.quizzes.where((quiz) => quiz.published == true).toList();

          if (publishedQuizzes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  const Text(
                    "No quizzes available yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your teacher will publish quizzes soon",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: publishedQuizzes.length,
            itemBuilder: (context, index) {
              final quiz = publishedQuizzes[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/quiz-play',
                      arguments: quiz,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.quiz,
                                color: Colors.indigo.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quiz.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildDifficultyBadge(quiz.difficulty),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Stats chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(
                              Icons.format_list_numbered,
                              "${quiz.questions.length} Questions",
                              Colors.blue,
                            ),
                            _buildInfoChip(
                              Icons.star,
                              "${quiz.totalMarks} Marks",
                              Colors.orange,
                            ),
                            _buildInfoChip(
                              Icons.timer,
                              "${quiz.timerMinutes} min",
                              Colors.green,
                            ),
                            _buildInfoChip(
                              Icons.calendar_today,
                              _formatDate(quiz.timestamp),
                              Colors.purple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Action button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/quiz-play',
                                  arguments: quiz,
                                );
                              },
                              icon: const Icon(Icons.play_arrow, size: 20),
                              label: const Text("Start Quiz"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = Colors.green;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'hard':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(
            alpha: 0.2), // FIXED: Use withValues instead of withOpacity
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
