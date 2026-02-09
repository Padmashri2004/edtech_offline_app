import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logger/logger.dart';

class AIService {
  final Logger _logger = Logger();

  static const int defaultMaxTokens = 256;
  static const int explanationMaxTokens = 128;

  /// Ensure Gemma model is installed and active before inference
  Future<dynamic> _getOrInstallModel({int maxTokens = defaultMaxTokens}) async {
    try {
      // Try to get an active model
      var model = await FlutterGemma.getActiveModel(maxTokens: maxTokens);
      return model;
    } catch (e) {
      _logger.w("⚠️ No active model found. Installing Gemma model...");

      try {
        // Install from your bundled asset path
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt, // valid enum constant
        ).fromAsset("assets/models/gemma.task").install();

        return await FlutterGemma.getActiveModel(maxTokens: maxTokens);
      } catch (installError) {
        _logger.e("❌ Failed to install Gemma model: $installError");
        return null;
      }
    }
  }

  /// Generate assessment questions based on prompt
  Future<String> generateAssessment({
    required String prompt,
    int maxTokens = defaultMaxTokens,
  }) async {
    try {
      final model = await _getOrInstallModel(maxTokens: maxTokens);
      if (model == null) {
        _logger.e("❌ AI Generation Error: No model available");
        return "[]";
      }

      final chat = await model.createChat();
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

      StringBuffer response = StringBuffer();
      await for (final chunk
          in chat.generateChatResponseAsync(maxTokens: maxTokens)) {
        response.write(chunk);
      }

      String result = response.toString();
      _logger.d("✅ Generated ${result.length} chars");
      return result.isNotEmpty ? result : "[]";
    } catch (e) {
      _logger.e("❌ AI Generation Error: $e");
      return "[]";
    }
  }

  /// Explain mistakes in student answers
  Future<String> explainMistake({
    required String question,
    required String studentAns,
    required String correctAns,
  }) async {
    try {
      final model = await _getOrInstallModel(maxTokens: explanationMaxTokens);
      if (model == null) {
        _logger.e("❌ XAI Error: No model available");
        return "Unable to generate explanation at this time.";
      }

      final chat = await model.createChat();
      String xaiPrompt = """
Q: "$question"
Student: "$studentAns"
Correct: "$correctAns"
Explain why wrong, correct concept, tip to remember. Max 80 words.
""";

      await chat.addQueryChunk(Message.text(text: xaiPrompt, isUser: true));

      StringBuffer feedback = StringBuffer();
      await for (final chunk
          in chat.generateChatResponseAsync(maxTokens: explanationMaxTokens)) {
        feedback.write(chunk);
      }

      return feedback.toString().isNotEmpty
          ? feedback.toString()
          : "Unable to generate explanation at this time.";
    } catch (e) {
      _logger.e("❌ XAI Error: $e");
      return "Unable to generate explanation at this time.";
    }
  }

  /// Validate AI response
  bool isResponseValid(String response) {
    return response.isNotEmpty && response != "[]" && response.length > 5;
  }
}
