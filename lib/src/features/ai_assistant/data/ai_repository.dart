import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';
import 'package:edtech_offline_app/src/core/ai/prompt_templates.dart';
import 'package:edtech_offline_app/src/core/utils/textbook_parser.dart';

class AIRepository {
  final AIService _aiService;
  final Logger _logger = Logger();

  AIRepository(this._aiService);

  /// Generates a quiz using your specific 'generateAssessment' method
  Future<List<Map<String, dynamic>>> getQuizFromChapter({
    required String rawContent,
    required String difficulty,
  }) async {
    try {
      final chunks = TextbookParser.cleanAndChunk(rawContent);
      final context = chunks.first;

      final prompt = PromptTemplates.quizGeneration(
        context: context,
        difficulty: difficulty,
      );

      _logger.i("🧠 Member 1: Calling generateAssessment for $difficulty level...");
      
      // Fixed: Now calling your existing method
      final response = await _aiService.generateAssessment(prompt: prompt);

      return List<Map<String, dynamic>>.from(jsonDecode(response));
    } catch (e) {
      _logger.e("❌ Member 1 Repository Error: $e");
      return [];
    }
  }

  /// Specialized call for XAI using your 'explainMistake' method
  Future<String> getMistakeExplanation({
    required String question, 
    required String studentAns, 
    required String correctAns
  }) async {
    _logger.i("🔍 Member 1: Requesting XAI feedback...");
    
    // Fixed: Now calling your existing XAI method
    return await _aiService.explainMistake(
      question: question,
      studentAns: studentAns,
      correctAns: correctAns,
    );
  }
}