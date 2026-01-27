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
    List<String>? focusTopics,
    List<String>? extractedImages,
  }) async {
    ExamModel? basicExam;
    ExamModel? advancedExam;

    // BASIC PAPER (100 marks)
    if (basicStudents.isNotEmpty) {
      _logger.i("🏗️ Generating BASIC Paper...");
      List<QuestionModel> q =
          await _generateBasicPaper(rawContent, focusTopics, chapterTitle);

      basicExam = ExamModel(
        title: "$chapterTitle (Basic)",
        difficulty: 'Basic',
        timestamp: DateTime.now().toIso8601String(),
        assignedStudents: basicStudents,
        questions: q,
      );

      await _quizRepository.saveExam(basicExam);
      _logger.i("✅ Basic: ${basicExam.totalMarks}M");
    }

    // ADVANCED PAPER (100 marks)
    if (advancedStudents.isNotEmpty) {
      _logger.i("🏗️ Generating ADVANCED Paper...");
      List<QuestionModel> q = await _generateAdvancedPaper(
          rawContent, focusTopics, extractedImages, chapterTitle);

      advancedExam = ExamModel(
        title: "$chapterTitle (Advanced)",
        difficulty: 'Advanced',
        timestamp: DateTime.now().toIso8601String(),
        assignedStudents: advancedStudents,
        questions: q,
      );

      await _quizRepository.saveExam(advancedExam);
      _logger.i("✅ Advanced: ${advancedExam.totalMarks}M");
    }

    return {'basic': basicExam, 'advanced': advancedExam};
  }

  // BASIC PAPER STRUCTURE (100 marks)
  Future<List<QuestionModel>> _generateBasicPaper(
      String text, List<String>? topics, String chapter) async {
    List<QuestionModel> q = [];

    q.addAll(await _gen(text, 'Basic', 'MCQ', 5, 1, topics, chapter));
    q.addAll(await _gen(text, 'Basic', 'Fill-up', 5, 1, topics, chapter,
        hints: true));
    q.addAll(await _gen(text, 'Basic', 'OddOneOut', 5, 1, topics, chapter));
    q.addAll(await _gen(text, 'Basic', 'Rearrange', 5, 1, topics, chapter));
    q.addAll(await _gen(text, 'Basic', 'MatchIt', 5, 1, topics, chapter));
    q.addAll(await _gen(text, 'Basic', 'ShortAns', 7, 5, topics, chapter));
    q.addAll(await _gen(text, 'Basic', 'LongAns', 7, 10, topics, chapter));

    return q;
  }

  // ADVANCED PAPER STRUCTURE (100 marks) - FIXED: 2nd T/F replaced with Rearrange
  Future<List<QuestionModel>> _generateAdvancedPaper(String text,
      List<String>? topics, List<String>? imgs, String chapter) async {
    List<QuestionModel> q = [];

    q.addAll(await _gen(text, 'Advanced', 'MCQ', 5, 1, topics, chapter));
    q.addAll(await _gen(text, 'Advanced', 'Fill-up', 5, 1, topics, chapter));
    q.addAll(await _gen(text, 'Advanced', 'True/False', 5, 1, topics, chapter));

    // FIXED: Replaced 2nd True/False with Rearrange as per requirements
    q.addAll(await _gen(text, 'Advanced', 'Rearrange', 5, 1, topics, chapter));

    q.addAll(await _gen(text, 'Advanced', 'ShortAns', 7, 5, topics, chapter));
    q.addAll(await _gen(text, 'Advanced', 'PictureBased', 1, 5, topics, chapter,
        imgs: imgs));
    q.addAll(await _gen(text, 'Advanced', 'LongAns', 7, 10, topics, chapter));

    return q;
  }

  Future<List<QuestionModel>> _gen(String text, String diff, String type,
      int count, int marks, List<String>? topics, String chapter,
      {bool hints = false, List<String>? imgs}) async {
    try {
      final raw = await _aiRepository.getQuizFromChapter(
        rawContent: text,
        difficulty: diff,
        type: type,
        count: count,
        hints: hints,
        focusTopics: topics,
        chapterTitle: chapter,
      );

      if (raw.isEmpty) return [];

      return raw.asMap().entries.map((e) {
        int idx = e.key;
        var d = e.value;

        String qText = d['q'] ?? d['question'] ?? "";
        String? img;

        if (type == 'PictureBased') {
          String topic = d['topic'] ?? d['answer'] ?? "concept";
          qText = "Case Study: Explain the diagram of **$topic**.";
          if (imgs != null && imgs.isNotEmpty) {
            img = imgs[idx % imgs.length];
          }
        }

        return QuestionModel(
          questionText: qText,
          options: d['o'] != null ? List<String>.from(d['o']) : [],
          correctAnswer: d['a'] ?? d['correct_answer'] ?? "",
          explanation: d['e'] ?? d['explanation'] ?? "",
          marks: marks,
          imagePath: img,
        );
      }).toList();
    } catch (e) {
      _logger.e("❌ Section $type error: $e");
      return [];
    }
  }
}
