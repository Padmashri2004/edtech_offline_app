import 'dart:convert';
import 'dart:math';
import 'package:logger/logger.dart';
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';
import 'package:edtech_offline_app/src/core/utils/textbook_parser.dart';
import 'package:edtech_offline_app/services/ai_prompt_service.dart';
// REMOVED: import 'package:flutter_gemma/flutter_gemma.dart';

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
    List<String>? focusTopics, // NEW Param
  }) async {
    try {
      final chunks = TextbookParser.cleanAndChunk(rawContent);
      if (chunks.isEmpty) return [];

      // Random chunk strategy
      final random = Random();
      final context = chunks[random.nextInt(chunks.length)];

      final prompt = _promptService.buildSectionPrompt(
        text: context,
        difficulty: difficulty,
        sectionType: type,
        count: count,
        hintsIncluded: hints,
        focusTopics: focusTopics, // Pass it down
      );

      _logger.i(
          " 🧠  Calling AI for $difficulty - $type (${focusTopics?.length ?? 0} topics)...");

      // Max tokens 2000 is safe for Nano model
      final response =
          await _aiService.generateAssessment(prompt: prompt, maxTokens: 2000);

      String cleanJson = _sanitizeJson(response);
      return List<Map<String, dynamic>>.from(jsonDecode(cleanJson));
    } catch (e) {
      _logger.e(" ❌  AI Repo Error: $e");
      return [];
    }
  }

  String _sanitizeJson(String raw) {
    try {
      String clean = raw.trim();
      // Remove markdown tags
      if (clean.contains('```')) {
        clean =
            clean.replaceAll(RegExp(r'^```[a-z]*'), '').replaceAll('```', '');
      }
      // Find brackets
      int start = clean.indexOf('[');
      int end = clean.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        return clean.substring(start, end + 1);
      }
      return "[]";
    } catch (e) {
      return "[]";
    }
  }
}
