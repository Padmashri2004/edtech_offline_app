import 'dart:convert';
import 'dart:math';
import 'package:logger/logger.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';
import 'package:edtech_offline_app/src/core/utils/textbook_parser.dart';
import 'package:edtech_offline_app/src/core/database/database_helper.dart';
import 'package:edtech_offline_app/services/ai_prompt_service.dart';
import 'package:edtech_offline_app/services/pdf_service.dart';
import 'dart:io';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';

class AIRepository {
  final AIService _aiService;
  final AiPromptService _promptService = AiPromptService();
  final Logger _logger = Logger();

  AIRepository(this._aiService);

  // --- Quiz Generation ---
  Future<List<Map<String, dynamic>>> getQuizFromChapter({
    required String rawContent,
    required String difficulty,
    required String type,
    int count = 5,
    bool hints = false,
    List<String>? focusTopics,
    String? chapterTitle,
  }) async {
    try {
      final chunks = TextbookParser.cleanAndChunk(rawContent);
      if (chunks.isEmpty) return [];

      final context = _selectBestChunk(chunks, focusTopics);

      final prompt = _promptService.buildSectionPrompt(
        text: context,
        difficulty: difficulty,
        sectionType: type,
        count: count,
        hintsIncluded: hints,
        focusTopics: focusTopics,
      );

      final response = await _aiService.generateAssessment(
        prompt: prompt,
        maxTokens: AIService.defaultMaxTokens,
      );

      if (!_aiService.isResponseValid(response)) return [];

      String cleanJson = _sanitizeJson(response);
      List<Map<String, dynamic>> questions;

      try {
        questions = List<Map<String, dynamic>>.from(jsonDecode(cleanJson));
      } catch (e) {
        _logger.w("⚠️ JSON decode failed, returning empty list");
        return [];
      }

      questions = _validateQuestions(questions, type);

      // Attach images if relevant
      if (chapterTitle != null) {
        final file = File("assets/${chapterTitle.replaceAll(' ', '_')}.pdf");
        if (await file.exists()) {
          final images = await PdfService().extractChapterImages(file, 1, 6);
          for (int i = 0; i < questions.length; i++) {
            if (questions[i]['q']
                .toString()
                .toLowerCase()
                .contains("photosynthesis")) {
              questions[i]['image_path'] =
                  images.isNotEmpty ? images.first : null;
              questions[i]['caption'] = "Photosynthesis diagram";
            }
          }
        }
      }

      if (chapterTitle != null && questions.isNotEmpty) {
        await _saveQuestionHistory(questions, chapterTitle, type);
      }

      _logger.i("✅ Generated ${questions.length} unique questions");
      return questions;
    } catch (e) {
      _logger.e("❌ AI Repo Error: $e");
      return [];
    }
  }

  // --- Exam Paper Generation ---
  Future<List<Map<String, dynamic>>> generateExamPaper({
    required String rawContent,
    required String tier, // "Basic" or "Advanced"
    String? chapterTitle,
    String? subject,
    String? className,
  }) async {
    final chunks = TextbookParser.cleanAndChunk(rawContent);
    if (chunks.isEmpty) return [];

    final context = chunks.first;
    List<Map<String, dynamic>> paper = [];

    if (tier == "Basic") {
      paper.addAll(await getQuizFromChapter(
          rawContent: context, difficulty: "Easy", type: "MCQ", count: 5));
      paper.addAll(await getQuizFromChapter(
          rawContent: context,
          difficulty: "Easy",
          type: "Fill-up",
          count: 5,
          hints: true));
      paper.addAll(await getQuizFromChapter(
          rawContent: context,
          difficulty: "Easy",
          type: "OddOneOut",
          count: 5));
      paper.addAll(await getQuizFromChapter(
          rawContent: context,
          difficulty: "Easy",
          type: "Rearrange",
          count: 5));
      paper.addAll(await getQuizFromChapter(
          rawContent: context,
          difficulty: "Medium",
          type: "ShortAns",
          count: 7));
      paper.addAll(await getQuizFromChapter(
          rawContent: context,
          difficulty: "Medium",
          type: "MatchIt",
          count: 5));
      paper.addAll(await getQuizFromChapter(
          rawContent: context, difficulty: "Hard", type: "LongAns", count: 7));
    } else {
      paper.addAll(await getQuizFromChapter(
          rawContent: context, difficulty: "Easy", type: "MCQ", count: 5));
      paper.addAll(await getQuizFromChapter(
          rawContent: context, difficulty: "Easy", type: "Fill-up", count: 5));
      paper.addAll(await getQuizFromChapter(
          rawContent: context,
          difficulty: "Easy",
          type: "True/False",
          count: 5));
      paper.addAll(await getQuizFromChapter(
          rawContent: context,
          difficulty: "Easy",
          type: "OddOneOut",
          count: 5));
      paper.addAll(await getQuizFromChapter(
          rawContent: context,
          difficulty: "Medium",
          type: "ShortAns",
          count: 7));
      paper.addAll(await getQuizFromChapter(
          rawContent: context,
          difficulty: "Medium",
          type: "CaseStudy",
          count: 1));
      paper.addAll(await getQuizFromChapter(
          rawContent: context, difficulty: "Hard", type: "LongAns", count: 7));
    }

    // ✅ Save exam to DB so dashboard shows it
    final exam = ExamModel(
      title: "${className ?? 'Class'} ${subject ?? 'Subject'} - $tier Tier",
      difficulty: tier,
      timestamp: DateTime.now().toIso8601String(),
      questions: paper
          .map((q) => QuestionModel(
                questionText: q['q'],
                options: q['o'],
                correctAnswer: q['a'],
                marks: 1,
                imagePath: q['image_path'],
              ))
          .toList(),
    );

    await QuizRepository().saveExam(exam);

    _logger.i("📄 Generated ${paper.length} questions for $tier tier exam");
    return paper;
  }

  // --- Validation, Deduplication, History ---
  List<Map<String, dynamic>> _validateQuestions(
      List<Map<String, dynamic>> questions, String type) {
    List<Map<String, dynamic>> validated = [];
    for (var q in questions) {
      String questionText = q['q'] ?? q['question'] ?? '';
      if (questionText.isEmpty || questionText.length < 10) continue;
      validated.add(q);
    }
    return validated;
  }

  Future<void> _saveQuestionHistory(List<Map<String, dynamic>> questions,
      String chapterTitle, String type) async {
    try {
      final db = await DatabaseHelper.instance.database;
      for (var q in questions) {
        String questionText = q['q'] ?? q['question'] ?? '';
        if (questionText.isEmpty) continue;
        String hash = _generateQuestionHash(questionText);
        await db.insert(
          'question_history',
          {
            'chapter_title': chapterTitle,
            'topic': type,
            'question_hash': hash,
            'generated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      _logger.d("💾 Saved ${questions.length} questions to history");
    } catch (e) {
      _logger.w("⚠️ Failed to save history: $e");
    }
  }

  String _generateQuestionHash(String questionText) {
    String normalized = questionText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    var bytes = utf8.encode(normalized);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _sanitizeJson(String raw) {
    try {
      String clean = raw
          .trim()
          .replaceAll('json', '')
          .replaceAll('', '')
          .replaceAll('\n', ' ');

      int start = clean.indexOf('[');
      int end = clean.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        return clean.substring(start, end + 1);
      }

      if (clean.startsWith('{') && clean.endsWith('}')) {
        return "[$clean]";
      }

      return clean; // fallback
    } catch (e) {
      _logger.e("❌ JSON sanitization failed: $e");
      return "[]";
    }
  }

  String _selectBestChunk(List<String> chunks, List<String>? focusTopics) {
    if (focusTopics == null || focusTopics.isEmpty) {
      return chunks[Random().nextInt(chunks.length)];
    }

    int bestScore = 0;
    String bestChunk = chunks.first;

    for (var chunk in chunks) {
      int score = 0;
      String lowerChunk = chunk.toLowerCase();
      for (var topic in focusTopics) {
        if (lowerChunk.contains(topic.toLowerCase())) {
          score += 10;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestChunk = chunk;
      }
    }

    return bestChunk;
  }
}
