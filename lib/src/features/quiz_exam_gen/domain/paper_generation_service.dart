import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/assessment_repository.dart';
import 'package:edtech_offline_app/services/ai_prompt_service.dart';
import 'package:logger/logger.dart';

class PaperGenerationService {
  final AIRepository _aiRepository;
  final AssessmentRepository _assessmentRepository = AssessmentRepository();
  final AiPromptService _promptService = AiPromptService();
  final Logger _logger = Logger();

  PaperGenerationService(this._aiRepository);

  // ✅ ENHANCED: Generate exam paper with batch processing
  Future<ExamModel> generatePaper({
    required String title,
    required String tier,
    required List<String> topics,
    required String content,
    Function(int, int, String)? onProgress,
  }) async {
    try {
      _logger.i('🎯 Generating exam paper: $title (Tier: $tier)');

      // ✅ Get question distribution (100 marks total)
      final distribution = _getTierDistribution(tier);
      final List<QuestionModel> allQuestions = [];

      int totalToGenerate =
          distribution.values.fold(0, (sum, count) => sum + count);

      onProgress?.call(0, totalToGenerate, 'Preparing content...');

      // Chunk content if too large
      final chunks = _promptService.chunkText(
        content,
        AiPromptService.maxTextLength,
      );

      int generated = 0;

      // Generate questions in batches by type
      for (var entry in distribution.entries) {
        final type = entry.key;
        final count = entry.value;
        final marksPerQ = _getMarksForType(type);

        onProgress?.call(
            generated, totalToGenerate, 'Generating $type questions...');

        // Process in small batches
        final batchSize = 3;
        for (int i = 0; i < count; i += batchSize) {
          int currentBatchSize =
              (i + batchSize > count) ? count - i : batchSize;

          try {
            for (int j = 0; j < currentBatchSize; j++) {
              int chunkIndex = (i + j) % chunks.length;
              String currentContext = chunks.isNotEmpty
                  ? chunks[chunkIndex]
                  : content.substring(
                      0, content.length > 100 ? 100 : content.length);

              var question = await _aiRepository.generateQuestion(
                type: type,
                difficulty: tier == 'Basic' ? 'Medium' : 'Hard',
                topic: topics.isNotEmpty
                    ? topics.first
                    : currentContext.substring(
                        0,
                        currentContext.length > 100
                            ? 100
                            : currentContext.length),
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
                  _logger.w('⚠️ Duplicate detected, regenerating...');
                  j--; // Retry
                }
              }

              await Future.delayed(const Duration(milliseconds: 100));
            }

            await Future.delayed(const Duration(milliseconds: 300));
          } catch (e) {
            _logger.e('❌ Error generating $type batch: $e');
          }
        }
      }

      // ✅ Calculate total marks
      final totalMarks = allQuestions.fold<int>(0, (sum, q) => sum + q.marks);

      // ✅ Create exam model
      final exam = ExamModel(
        title: title,
        type: 'exam',
        difficulty: tier,
        timerMinutes: tier == 'Basic' ? 180 : 180, // ✅ 3 hours for both
        totalMarks: totalMarks,
        questions: allQuestions,
        timestamp: DateTime.now().toIso8601String(),
        published: false,
      );

      onProgress?.call(totalToGenerate, totalToGenerate,
          'Exam paper generated successfully!');

      _logger
          .i('✅ Generated ${allQuestions.length} questions, $totalMarks marks');
      return exam;
    } catch (e) {
      _logger.e('❌ Error generating paper: $e');
      rethrow;
    }
  }

  // ✅ FIXED: Correct distribution for 100 marks
  Map<String, int> _getTierDistribution(String tier) {
    if (tier == 'Basic') {
      // Basic Tier = 100 marks total
      return {
        'MCQ': 20, // 20 × 1 = 20 marks
        'Fill-up': 20, // 15 × 1 = 15 marks
        'True/False': 5, // 5 × 1 = 5 marks
        'OddOneOut': 5, // 5 × 1 = 5 marks
        'ShortAns': 7, // 7 × 5 = 35 marks (Attempt 5 out of 7)
        'LongAns': 7, // 7 × 5 = 35 marks (Attempt 5 out of 7)
      };
    } else {
      // Advanced Tier = 100 marks total
      return {
        'MCQ': 20, // 20 × 1 = 20 marks
        'Fill-up': 10, // 10 × 1 = 10 marks
        'True/False': 5, // 5 × 1 = 5 marks
        'OddOneOut': 5, // 5 × 1 = 5 marks
        'ShortAns': 7, // 7 × 5 = 21 marks (Attempt 5 out of 7)
        'LongAns': 7, // 7 × 5 = 35 marks (Attempt 5 out of 7)
        'CaseStudy': 1, // 1 × 10 = 10 marks
      };
    }
  }

  // ✅ FIXED: Marks per question type
  int _getMarksForType(String type) {
    switch (type) {
      case 'MCQ':
      case 'Fill-up':
      case 'True/False':
      case 'OddOneOut':
        return 1;
      case 'ShortAns':
        return 5;
      case 'LongAns':
        return 5;
      case 'CaseStudy':
        return 10;
      default:
        return 1;
    }
  }

  // Deduplicate questions
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

  // Assign IDs to questions
  List<QuestionModel> assignQuestionIds(
      List<QuestionModel> questions, int examId) {
    return questions.asMap().entries.map((entry) {
      return entry.value.copyWith(
        id: examId * 1000 + entry.key,
      );
    }).toList();
  }
}
