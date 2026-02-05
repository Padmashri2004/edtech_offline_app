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

    // --- BASIC TIER (100 Marks) ---
    if (basicStudents.isNotEmpty) {
      _logger.i("🏗️ Generating BASIC Paper (100M)...");
      List<QuestionModel> q = [];

      q.addAll(await _gen(
          rawContent, 'Basic', 'MCQ', 5, 1, focusTopics, chapterTitle,
          header: "Section 1: MCQ (5x1=5)"));
      q.addAll(await _gen(
          rawContent, 'Basic', 'Fill-up', 5, 1, focusTopics, chapterTitle,
          hints: true,
          header: "Section 2: Fill-in-the-Blanks (Hinted) (5x1=5)"));
      q.addAll(await _gen(
          rawContent, 'Basic', 'OddOneOut', 5, 1, focusTopics, chapterTitle,
          header: "Section 3: Odd One Out (5x1=5)"));
      q.addAll(await _gen(
          rawContent, 'Basic', 'Rearrange', 5, 1, focusTopics, chapterTitle,
          header: "Section 4: Rearrange (5x1=5)"));
      q.addAll(await _gen(
          rawContent, 'Basic', 'MatchIt', 5, 1, focusTopics, chapterTitle,
          header: "Section 5: Match the Following (5x1=5)"));
      q.addAll(await _gen(
          rawContent, 'Basic', 'ShortAns', 7, 5, focusTopics, chapterTitle,
          header: "Section 6: Short Answer - Choose 5 (5x5=25)"));
      q.addAll(await _gen(
          rawContent, 'Basic', 'LongAns', 7, 10, focusTopics, chapterTitle,
          header: "Section 7: Long Answer - Choose 5 (5x10=50)"));

      basicExam = ExamModel(
        title: "$chapterTitle (Basic)",
        difficulty: 'Basic',
        timestamp: DateTime.now().toIso8601String(),
        assignedStudents: basicStudents,
        questions: q,
        // Removed totalMarks parameter as it is not in your model
      );
      await _quizRepository.saveExam(basicExam);
    }

    // --- ADVANCED TIER (100 Marks) ---
    if (advancedStudents.isNotEmpty) {
      _logger.i("🏗️ Generating ADVANCED Paper (100M)...");
      List<QuestionModel> q = [];

      q.addAll(await _gen(
          rawContent, 'Advanced', 'MCQ', 5, 1, focusTopics, chapterTitle,
          header: "Section 1: MCQ (5x1=5)"));
      q.addAll(await _gen(
          rawContent, 'Advanced', 'Fill-up', 5, 1, focusTopics, chapterTitle,
          hints: false,
          header: "Section 2: Fill-in-the-Blanks (No Hint) (5x1=5)"));
      q.addAll(await _gen(
          rawContent, 'Advanced', 'True/False', 5, 1, focusTopics, chapterTitle,
          header: "Section 3: True/False (5x1=5)"));
      q.addAll(await _gen(
          rawContent, 'Advanced', 'Rearrange', 5, 1, focusTopics, chapterTitle,
          header: "Section 4: Rearrange (5x1=5)"));
      q.addAll(await _gen(
          rawContent, 'Advanced', 'ShortAns', 7, 5, focusTopics, chapterTitle,
          header: "Section 5: Short Answer - Choose 5 (5x5=25)"));
      q.addAll(await _gen(rawContent, 'Advanced', 'PictureBased', 1, 5,
          focusTopics, chapterTitle,
          imgs: extractedImages, header: "Section 6: Case Study (1x5=5)"));
      q.addAll(await _gen(
          rawContent, 'Advanced', 'LongAns', 7, 10, focusTopics, chapterTitle,
          header: "Section 7: Long Answer - Choose 5 (5x10=50)"));

      advancedExam = ExamModel(
        title: "$chapterTitle (Advanced)",
        difficulty: 'Advanced',
        timestamp: DateTime.now().toIso8601String(),
        assignedStudents: advancedStudents,
        questions: q,
        // Removed totalMarks parameter
      );
      await _quizRepository.saveExam(advancedExam);
    }

    return {'basic': basicExam, 'advanced': advancedExam};
  }

  Future<List<QuestionModel>> _gen(String text, String diff, String type,
      int count, int marks, List<String>? topics, String chapter,
      {bool hints = false, List<String>? imgs, required String header}) async {
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

      if (raw.isEmpty) {
        return [];
      }

      List<QuestionModel> questions = raw.asMap().entries.map((e) {
        int idx = e.key;
        var d = e.value;
        String qText = d['q'] ?? d['question'] ?? "";

        // Handle Picture logic
        String? img;
        if (type == 'PictureBased' && imgs != null && imgs.isNotEmpty) {
          img = imgs[idx % imgs.length];
          if (qText.length < 5) {
            qText = "Analyze the diagram and explain its key components.";
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

      if (questions.isNotEmpty) {
        String original = questions[0].questionText;
        String injected = "///SECTION: $header///$original";

        questions[0] = QuestionModel(
          id: questions[0].id,
          examId: questions[0].examId,
          questionText: injected,
          options: questions[0].options,
          correctAnswer: questions[0].correctAnswer,
          explanation: questions[0].explanation,
          marks: questions[0].marks,
          imagePath: questions[0].imagePath,
        );
      }

      return questions;
    } catch (e) {
      _logger.e("❌ Section $type error: $e");
      return [];
    }
  }
}
