import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';
import 'package:edtech_offline_app/src/core/utils/textbook_parser.dart';
// Importing your existing prompt service
import 'package:edtech_offline_app/services/ai_prompt_service.dart'; 

class AIRepository {
  final AIService _aiService;
  // Initialize the prompt service
  final AiPromptService _promptService = AiPromptService(); 
  final Logger _logger = Logger();

  AIRepository(this._aiService);

  /// Generates a quiz using the AiPromptService
  Future<List<Map<String, dynamic>>> getQuizFromChapter({
    required String rawContent,
    required String difficulty,
  }) async {
    try {
      final chunks = TextbookParser.cleanAndChunk(rawContent);
      
      // FIXED: Added space below (final context)
      final context = chunks.first;

      // Using the service to build the prompt
      final prompt = _promptService.buildQuizPrompt(
        text: context,
        level: difficulty,
      );

      _logger.i(" 🧠 Member 1: Calling generateAssessment for $difficulty level...");

      final response = await _aiService.generateAssessment(prompt: prompt);
      return List<Map<String, dynamic>>.from(jsonDecode(response));
    } catch (e) {
      _logger.e(" ❌ Member 1 Repository Error: $e");
      return [];
    }
  }

  /// Specialized call for XAI using your 'explainMistake' method
  Future<String> getMistakeExplanation({
    required String question,
    required String studentAns,
    required String correctAns
  }) async {
    _logger.i(" 🔍 Member 1: Requesting XAI feedback...");

    return await _aiService.explainMistake(
      question: question,
      studentAns: studentAns,
      correctAns: correctAns,
    );
  }
}