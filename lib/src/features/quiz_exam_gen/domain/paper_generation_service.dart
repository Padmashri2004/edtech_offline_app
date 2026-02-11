import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/assessment_repository.dart';
import 'package:logger/logger.dart';

class PaperGenerationService {
  final AIRepository _aiRepository;
  final AssessmentRepository _assessmentRepository = AssessmentRepository();
  final Logger _logger = Logger();

  PaperGenerationService(this._aiRepository);

  // ✅ NEW: Generate exam paper
  Future<ExamModel> generatePaper({
    required String title,
    required String tier,
    required List<String> topics,
    required String content,
    Function(int, int, String)? onProgress,
  }) async {
    try {
      _logger.i('Generating exam paper: $title (Tier: $tier)');

      // Determine question distribution based on tier
      final distribution = _getTierDistribution(tier);

      final List<QuestionModel> allQuestions = [];
      int totalToGenerate =
          distribution.values.fold(0, (sum, count) => sum + count);
      int generated = 0;

      // Generate questions for each type
      for (var entry in distribution.entries) {
        final type = entry.key;
        final count = entry.value;
        final marksPerQ = _getMarksForType(type);

        onProgress?.call(
            generated, totalToGenerate, 'Generating $type questions...');

        for (int i = 0; i < count; i++) {
          try {
            var question = await _aiRepository.generateQuestion(
              type: type,
              difficulty: tier == 'Basic' ? 'Medium' : 'Hard',
              topic:
                  topics.isNotEmpty ? topics.first : content.substring(0, 100),
              marks: marksPerQ,
            );

            if (question != null) {
              // Check for duplicates
              final exists =
                  await _assessmentRepository.questionExists(question);

              if (!exists) {
                allQuestions.add(question);
                await _assessmentRepository.saveQuestionHistory(question);
                generated++;
                onProgress?.call(generated, totalToGenerate,
                    'Generated $generated/$totalToGenerate questions');
              } else {
                _logger.w('Duplicate question detected, regenerating...');
                i--; // Retry this question
              }
            }
          } catch (e) {
            _logger.e('Error generating question: $e');
          }

          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Calculate total marks
      final totalMarks = allQuestions.fold<int>(0, (sum, q) => sum + q.marks);

      final exam = ExamModel(
        title: title,
        type: 'exam',
        difficulty: tier,
        timerMinutes: tier == 'Basic' ? 90 : 120,
        totalMarks: totalMarks,
        questions: allQuestions,
        timestamp: DateTime.now().toIso8601String(),
        published: false,
      );

      onProgress?.call(totalToGenerate, totalToGenerate,
          'Exam paper generated successfully!');

      return exam;
    } catch (e) {
      _logger.e('Error generating paper: $e');
      rethrow;
    }
  }

  // Get question distribution for tier
  Map<String, int> _getTierDistribution(String tier) {
    if (tier == 'Basic') {
      return {
        'MCQ': 10,
        'Fill-up': 5,
        'True/False': 5,
        'ShortAns': 5,
      };
    } else {
      // Advanced
      return {
        'MCQ': 8,
        'Fill-up': 4,
        'OddOneOut': 3,
        'ShortAns': 4,
        'LongAns': 3,
        'CaseStudy': 1,
      };
    }
  }

  // Get marks for question type
  int _getMarksForType(String type) {
    switch (type) {
      case 'MCQ':
      case 'Fill-up':
      case 'True/False':
      case 'OddOneOut':
        return 1;
      case 'ShortAns':
        return 3;
      case 'LongAns':
        return 5;
      case 'CaseStudy':
        return 8;
      default:
        return 1;
    }
  }

  // ✅ FIXED: Deduplicate questions using copyWith
  Future<List<QuestionModel>> deduplicateQuestions(
      List<QuestionModel> questions) async {
    final unique = <QuestionModel>[];

    for (var question in questions) {
      final exists = await _assessmentRepository.questionExists(question);

      if (!exists) {
        unique.add(question);
        await _assessmentRepository.saveQuestionHistory(question);
      }
    }

    return unique;
  }

  // ✅ FIXED: Assign IDs to questions using copyWith
  List<QuestionModel> assignQuestionIds(
      List<QuestionModel> questions, int examId) {
    return questions.asMap().entries.map((entry) {
      // ✅ FIXED: Use copyWith instead of direct assignment
      return entry.value.copyWith(
        id: examId * 1000 + entry.key, // Generate unique ID
      );
    }).toList();
  }
}
