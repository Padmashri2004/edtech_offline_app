import 'dart:convert'; // ✅ Needed for jsonDecode / jsonEncode
import 'package:logger/logger.dart';
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';

class AIRepository {
  final AIService _aiService = AIService();
  final Logger _logger = Logger();

  /// Generate assessment questions using AI
  Future<List<Map<String, dynamic>>> generateAssessment({
    required String prompt,
    int maxTokens = AIService.defaultMaxTokens,
  }) async {
    try {
      final response = await _aiService.generateAssessment(
        prompt: prompt,
        maxTokens: maxTokens,
      );

      if (!_aiService.isResponseValid(response)) {
        _logger.w("⚠️ Invalid AI response for assessment");
        return [];
      }

      // Attempt to parse JSON-like response into structured questions
      try {
        final parsed = _parseResponse(response);
        return parsed;
      } catch (e) {
        _logger.e("❌ Failed to parse AI response: $e");
        return [];
      }
    } catch (e) {
      _logger.e("❌ Assessment generation error: $e");
      return [];
    }
  }

  /// Generate exam paper directly from teacher selections
  Future<List<Map<String, dynamic>>> generateExamPaper({
    required String rawContent,
    required String tier, // Easy / Medium / Hard
    required List<Map<String, dynamic>>
        types, // Teacher-selected question types
    void Function(double progress)? onProgress, // ✅ added for progress updates
  }) async {
    List<Map<String, dynamic>> paper = [];

    for (int i = 0; i < types.length; i++) {
      final typeConfig = types[i];
      final type = typeConfig['type'];
      final count = typeConfig['count'];
      final marks = typeConfig['marks'];

      // Build a prompt for each type
      final prompt = """
Generate $count $tier questions of type $type
from the following content: $rawContent.
Each question should include:
- question
- options (if applicable)
- correct
- explanation
- marks ($marks per question)
Format output as JSON list.
""";

      final questions = await generateAssessment(prompt: prompt);

      // Attach marks per question explicitly
      for (var q in questions) {
        q['marks'] = marks;
      }

      paper.addAll(questions);

      // ✅ Update progress after each type is processed
      onProgress?.call((i + 1) / types.length);
    }

    _logger.i("📄 Generated ${paper.length} questions for $tier tier exam");
    return paper;
  }

  /// Explain mistakes in student answers
  Future<String> explainMistake({
    required String question,
    required String studentAns,
    required String correctAns,
  }) async {
    try {
      final response = await _aiService.explainMistake(
        question: question,
        studentAns: studentAns,
        correctAns: correctAns,
      );

      return response;
    } catch (e) {
      _logger.e("❌ Mistake explanation error: $e");
      return "Unable to generate explanation at this time.";
    }
  }

  /// Internal helper: parse AI JSON-like response into structured list
  List<Map<String, dynamic>> _parseResponse(String response) {
    try {
      String cleaned = response.trim();

      // Ensure starts with [ and ends with ]
      if (!cleaned.startsWith("[")) {
        cleaned = "[$cleaned]";
      }

      final decoded = jsonDecode(cleaned);

      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      } else {
        _logger.w("⚠️ Response not a list, returning empty");
        return [];
      }
    } catch (e) {
      _logger.w("⚠️ Response not valid JSON, returning empty list");
      return [];
    }
  }
}
