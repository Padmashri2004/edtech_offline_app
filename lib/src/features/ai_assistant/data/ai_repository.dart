import 'dart:convert';
import 'dart:math';
import 'package:logger/logger.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';
import 'package:edtech_offline_app/src/core/utils/textbook_parser.dart';
import 'package:edtech_offline_app/src/core/database/database_helper.dart';
import 'package:edtech_offline_app/services/ai_prompt_service.dart';

class AIRepository {
  final AIService _aiService;
  final AiPromptService _promptService = AiPromptService();
  final Logger _logger = Logger();

  AIRepository(this._aiService);

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
      // FIXED: Pre-generation deduplication check
      if (chapterTitle != null) {
        int existingCount = await _getExistingQuestionCount(chapterTitle, type);
        _logger.i(
            "📊 Found $existingCount existing $type questions for $chapterTitle");
      }

      final chunks = TextbookParser.cleanAndChunk(rawContent);
      if (chunks.isEmpty) {
        _logger.w("⚠️ No valid chunks generated");
        return [];
      }

      final context = _selectBestChunk(chunks, focusTopics);

      final prompt = _promptService.buildSectionPrompt(
        text: context,
        difficulty: difficulty,
        sectionType: type,
        count: count,
        hintsIncluded: hints,
        focusTopics: focusTopics,
      );

      // FIXED: Use reduced token limit
      _logger.i("🧠 Calling AI for $difficulty - $type...");
      final response = await _aiService.generateAssessment(
        prompt: prompt,
        maxTokens: AIService.defaultMaxTokens,
      );

      if (!_aiService.isResponseValid(response)) {
        _logger.e("❌ Invalid AI response");
        return [];
      }

      String cleanJson = _sanitizeJson(response);
      List<Map<String, dynamic>> questions =
          List<Map<String, dynamic>>.from(jsonDecode(cleanJson));

      // FIXED: Post-generation validation
      questions = _validateQuestions(questions, type);

      if (chapterTitle != null) {
        questions = await _filterDuplicates(questions, chapterTitle, type);
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

  // NEW: Pre-generation duplicate check
  Future<int> _getExistingQuestionCount(String chapter, String type) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM question_history WHERE chapter_title = ? AND topic = ?',
          [chapter, type]);
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // NEW: Question validation for quality control
  List<Map<String, dynamic>> _validateQuestions(
      List<Map<String, dynamic>> questions, String type) {
    List<Map<String, dynamic>> validated = [];

    for (var q in questions) {
      bool isValid = true;
      String questionText = q['q'] ?? q['question'] ?? '';

      // Validate question text exists
      if (questionText.isEmpty || questionText.length < 10) {
        _logger.w("⚠️ Skipping invalid question (too short)");
        continue;
      }

      // Validate MCQ distractors
      if (type == 'MCQ') {
        List<dynamic> options = q['o'] ?? [];
        if (options.length < 4) {
          _logger.w("⚠️ Skipping MCQ with < 4 options");
          continue;
        }

        // Check for non-plausible distractors
        String answer = q['a'] ?? '';
        if (!_hasPlausibleDistractors(questionText, options, answer)) {
          _logger.w("⚠️ Skipping MCQ with implausible distractors");
          continue;
        }
      }

      // Validate Fill-up hints
      if (type == 'Fill-up') {
        if (questionText.contains('starts with') ||
            questionText.contains('first letter')) {
          _logger.w("⚠️ Skipping Fill-up with letter hint");
          continue;
        }
      }

      if (isValid) {
        validated.add(q);
      }
    }

    return validated;
  }

  // NEW: Distractor plausibility check
  bool _hasPlausibleDistractors(
      String question, List<dynamic> options, String answer) {
    // Extract subject keywords from question
    final keywords = _extractKeywords(question);
    if (keywords.isEmpty) return true; // Cannot validate

    int plausibleCount = 0;
    for (var opt in options) {
      String option = opt.toString().toLowerCase();
      if (option == answer.toLowerCase()) continue;

      // Check if distractor contains at least one subject keyword
      bool isPlausible = keywords.any((kw) => option.contains(kw));
      if (isPlausible) plausibleCount++;
    }

    // At least 2 out of 3 distractors should be plausible
    return plausibleCount >= 2;
  }

  List<String> _extractKeywords(String text) {
    // Simple keyword extraction (can be enhanced)
    final commonWords = ['the', 'is', 'are', 'was', 'were', 'in', 'on', 'at'];
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    return words
        .where((w) => w.length > 4 && !commonWords.contains(w))
        .take(5)
        .toList();
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

  Future<List<Map<String, dynamic>>> _filterDuplicates(
    List<Map<String, dynamic>> questions,
    String chapterTitle,
    String type,
  ) async {
    List<Map<String, dynamic>> uniqueQuestions = [];

    for (var question in questions) {
      String questionText = question['q'] ?? question['question'] ?? '';
      String hash = _generateQuestionHash(questionText);

      bool isDuplicate = await _isQuestionDuplicate(hash, chapterTitle);

      if (!isDuplicate) {
        uniqueQuestions.add(question);
      } else {
        _logger.d("⚠️ Skipping duplicate");
      }
    }

    return uniqueQuestions;
  }

  Future<bool> _isQuestionDuplicate(String hash, String chapterTitle) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'question_history',
        where: 'question_hash = ? AND chapter_title = ?',
        whereArgs: [hash, chapterTitle],
      );

      return result.isNotEmpty;
    } catch (e) {
      _logger.w("⚠️ Duplicate check failed: $e");
      return false;
    }
  }

  Future<void> _saveQuestionHistory(
    List<Map<String, dynamic>> questions,
    String chapterTitle,
    String type,
  ) async {
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
      String clean = raw.trim();

      if (clean.contains('```')) {
        clean = clean
            .replaceAll(RegExp(r'^```[a-z]*\n?', multiLine: true), '')
            .replaceAll('```', '');
      }

      int start = clean.indexOf('[');
      int end = clean.lastIndexOf(']');

      if (start != -1 && end != -1 && end > start) {
        return clean.substring(start, end + 1);
      }

      return "[]";
    } catch (e) {
      _logger.e("❌ JSON sanitization failed: $e");
      return "[]";
    }
  }

  Future<void> clearOldHistory({int daysToKeep = 30}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final cutoffDate =
          DateTime.now().subtract(Duration(days: daysToKeep)).toIso8601String();

      int deleted = await db.delete(
        'question_history',
        where: 'generated_at < ?',
        whereArgs: [cutoffDate],
      );

      _logger.i("🗑️ Cleared $deleted old question records");
    } catch (e) {
      _logger.w("⚠️ History cleanup failed: $e");
    }
  }
}
