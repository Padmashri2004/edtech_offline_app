import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:logger/logger.dart';

class PaperGenerationService {
  final AIRepository _aiRepository;
  final QuizRepository _quizRepository;
  final Logger _logger = Logger();

  PaperGenerationService({
    required AIRepository aiRepository,
    required QuizRepository quizRepository,
  })  : _aiRepository = aiRepository,
        _quizRepository = quizRepository;

  Future<Map<String, ExamModel?>> generateDifferentiatedPapers({
    required String chapterTitle,
    required String rawContent,
    required List<String> basicStudents,
    required List<String> advancedStudents,
  }) async {
    ExamModel? basicExam;
    ExamModel? advancedExam;

    // --- 1. BASIC PAPER (100 Marks) ---
    if (basicStudents.isNotEmpty) {
      _logger.i("🏗️ Generating BASIC Paper (7 Sections)...");
      List<QuestionModel> basicQ = [];

      // Chained Generation
      basicQ.addAll(await _genSection(rawContent, 'Basic', 'MCQ', 5));
      basicQ.addAll(
          await _genSection(rawContent, 'Basic', 'Fill-up', 5, hints: true));
      basicQ.addAll(await _genSection(rawContent, 'Basic', 'OddOneOut', 5));
      basicQ.addAll(await _genSection(rawContent, 'Basic', 'Rearrange', 5));
      basicQ.addAll(await _genSection(rawContent, 'Basic', 'MatchIt', 5));
      basicQ.addAll(await _genSection(rawContent, 'Basic', 'ShortAns', 7));
      basicQ.addAll(await _genSection(rawContent, 'Basic', 'LongAns', 7));

      basicExam = ExamModel(
        title: "$chapterTitle (Basic)",
        difficulty: 'Basic',
        timestamp: DateTime.now().toIso8601String(),
        questions: basicQ,
      );
      await _quizRepository.saveExam(basicExam);
    }

    // --- 2. ADVANCED PAPER (100 Marks) ---
    if (advancedStudents.isNotEmpty) {
      _logger.i("🏗️ Generating ADVANCED Paper (7 Sections)...");
      List<QuestionModel> advQ = [];

      advQ.addAll(await _genSection(rawContent, 'Advanced', 'MCQ', 5));
      advQ.addAll(await _genSection(rawContent, 'Advanced', 'Fill-up', 5,
          hints: false));
      advQ.addAll(await _genSection(rawContent, 'Advanced', 'True/False', 5));
      advQ.addAll(
          await _genSection(rawContent, 'Advanced', 'AssertionReason', 5));
      advQ.addAll(await _genSection(rawContent, 'Advanced', 'ShortAns', 7));
      advQ.addAll(await _genSection(rawContent, 'Advanced', 'CaseStudy', 1));
      advQ.addAll(await _genSection(rawContent, 'Advanced', 'LongAns', 7));

      advancedExam = ExamModel(
        title: "$chapterTitle (Advanced)",
        difficulty: 'Advanced',
        timestamp: DateTime.now().toIso8601String(),
        questions: advQ,
      );
      await _quizRepository.saveExam(advancedExam);
    }

    return {'basic': basicExam, 'advanced': advancedExam};
  }

  Future<List<QuestionModel>> _genSection(
      String text, String diff, String type, int count,
      {bool hints = false}) async {
    try {
      // Breathing room for the device
      await Future.delayed(const Duration(milliseconds: 100));

      final rawList = await _aiRepository.getQuizFromChapter(
          rawContent: text,
          difficulty: diff,
          type: type,
          count: count,
          hints: hints);

      return rawList.map((q) {
        var model = QuestionModel.fromMap(q);
        // Prefix Question Text with Type for the PDF Renderer to detect
        return QuestionModel(
            id: model.id,
            questionText: "[$type] ${model.questionText}",
            options: model.options,
            correctAnswer: model.correctAnswer,
            explanation: model.explanation);
      }).toList();
    } catch (e) {
      _logger.e("Skipping section $type due to error: $e");
      return [];
    }
  }
}
