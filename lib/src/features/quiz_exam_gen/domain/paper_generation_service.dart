import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:logger/logger.dart';

/// Service dedicated to Module 6: Question Paper Generation
/// Handles the logic for splitting a class into tiers and generating
/// distinct Basic vs. Advanced papers.
class PaperGenerationService {
  final AIRepository _aiRepository;
  final QuizRepository _quizRepository;
  final Logger _logger = Logger();

  PaperGenerationService({
    required AIRepository aiRepository,
    required QuizRepository quizRepository,
  })  : _aiRepository = aiRepository,
        _quizRepository = quizRepository;

  /// Generates two sets of question papers (Basic & Advanced) based on the textbook content.
  /// Returns a Map containing both created exams.
  Future<Map<String, ExamModel?>> generateDifferentiatedPapers({
    required String chapterTitle,
    required String rawContent,
    required int basicStudentCount,
    required int advancedStudentCount,
  }) async {
    _logger.i(" 📄 Member 1: Starting Module 6 Auto-Generation for $chapterTitle");

    // 1. Generate Basic Tier Paper
    ExamModel? basicExam;
    if (basicStudentCount > 0) {
      _logger.i(" ⚙️ Generating BASIC tier for $basicStudentCount students...");
      final basicQuestions = await _aiRepository.getQuizFromChapter(
        rawContent: rawContent,
        difficulty: 'Basic', // Matches Module 6 requirement [cite: 1684]
      );

      if (basicQuestions.isNotEmpty) {
        basicExam = ExamModel(
          title: "$chapterTitle - Basic Tier",
          difficulty: 'Basic',
          timestamp: DateTime.now().toIso8601String(),
          questions: basicQuestions.map((q) => QuestionModel.fromMap(q)).toList(),
        );
        await _quizRepository.saveExam(basicExam);
      }
    }

    // 2. Generate Advanced Tier Paper
    ExamModel? advancedExam;
    if (advancedStudentCount > 0) {
      _logger.i(" ⚙️ Generating ADVANCED tier for $advancedStudentCount students...");
      final advancedQuestions = await _aiRepository.getQuizFromChapter(
        rawContent: rawContent,
        difficulty: 'Advanced', // Matches Module 6 requirement [cite: 1684]
      );

      if (advancedQuestions.isNotEmpty) {
        advancedExam = ExamModel(
          title: "$chapterTitle - Advanced Tier",
          difficulty: 'Advanced',
          timestamp: DateTime.now().toIso8601String(),
          questions: advancedQuestions.map((q) => QuestionModel.fromMap(q)).toList(),
        );
        await _quizRepository.saveExam(advancedExam);
      }
    }

    _logger.i(" ✅ Module 6 Generation Complete.");
    
    return {
      'basic': basicExam,
      'advanced': advancedExam,
    };
  }
}