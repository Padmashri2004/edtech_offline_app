import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logger/logger.dart';

class AIService {
  final Logger _logger = Logger();

  // FIXED: Optimized for Gemma 3-270M
  static const int defaultMaxTokens = 256; // Reduced from 1024
  static const int explanationMaxTokens = 128; // Reduced from 512

  Future<String> generateAssessment({
    required String prompt,
    int maxTokens = defaultMaxTokens,
  }) async {
    try {
      final model = await FlutterGemma.getActiveModel(maxTokens: maxTokens);
      final chat = await model.createChat();

      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

      StringBuffer response = StringBuffer();
      await for (final chunk in chat.generateChatResponseAsync()) {
        response.write(chunk);
      }

      String result = response.toString();
      _logger.d("✅ Generated ${result.length} chars");

      return result;
    } catch (e) {
      _logger.e("❌ AI Generation Error: $e");
      return "[]";
    }
  }

  Future<String> explainMistake({
    required String question,
    required String studentAns,
    required String correctAns,
  }) async {
    try {
      final model =
          await FlutterGemma.getActiveModel(maxTokens: explanationMaxTokens);
      final chat = await model.createChat();

      // FIXED: Shorter prompt for 270M model
      String xaiPrompt = """
Q: "$question"
Student: "$studentAns"
Correct: "$correctAns"

Explain why wrong, correct concept, tip to remember. Max 80 words.
""";

      await chat.addQueryChunk(Message.text(text: xaiPrompt, isUser: true));

      StringBuffer feedback = StringBuffer();
      await for (final chunk in chat.generateChatResponseAsync()) {
        feedback.write(chunk);
      }

      return feedback.toString();
    } catch (e) {
      _logger.e("❌ XAI Error: $e");
      return "Unable to generate explanation at this time.";
    }
  }

  Future<String> evaluateProgress(String perfData) async {
    try {
      final model =
          await FlutterGemma.getActiveModel(maxTokens: explanationMaxTokens);
      final chat = await model.createChat();

      // FIXED: Simplified prompt
      String agentPrompt = """
Student data: $perfData
Should extend deadline? YES/NO and why? (2 sentences max)
""";

      await chat.addQueryChunk(Message.text(text: agentPrompt, isUser: true));

      StringBuffer suggestion = StringBuffer();
      await for (final chunk in chat.generateChatResponseAsync()) {
        suggestion.write(chunk);
      }

      return suggestion.toString();
    } catch (e) {
      _logger.e("❌ Agentic AI Error: $e");
      return "NO - Unable to analyze at this time.";
    }
  }

  bool isResponseValid(String response) {
    return response.isNotEmpty && response != "[]" && response.length > 10;
  }
}
