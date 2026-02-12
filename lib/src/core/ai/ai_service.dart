import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logger/logger.dart';

class AIService {
  final Logger _logger = Logger();

  // Optimized token limits for mobile NPU/GPU
  static const int defaultMaxTokens = 512;
  static const int explanationMaxTokens = 256;

  /// Ensures the Gemma 270M model is initialized and ready for inference.
  Future<dynamic> _getOrInstallModel({int maxTokens = defaultMaxTokens}) async {
    try {
      // Check if a model is already active in memory
      var model = await FlutterGemma.getActiveModel(maxTokens: maxTokens);
      return model;
    } catch (e) {
      _logger.w("⚠️ No active model found. Initializing Gemma installation...");
      try {
        // Trigger installation from the local asset bundle
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
        ).fromAsset("assets/models/gemma.task").install();

        return await FlutterGemma.getActiveModel(maxTokens: maxTokens);
      } catch (installError) {
        _logger.e("❌ Critical: Failed to install Gemma model: $installError");
        return null;
      }
    }
  }

  /// Generates a Quiz or Assessment based on a structured prompt.
  /// Uses regex and substring slicing to ensure a clean data output.
  Future<String> generateAssessment({
    required String prompt,
    int maxTokens = defaultMaxTokens,
  }) async {
    try {
      final model = await _getOrInstallModel(maxTokens: maxTokens);
      if (model == null) return "[]";

      final chat = await model.createChat();
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

      StringBuffer responseBuffer = StringBuffer();

      // Stream chunks directly from the native engine
      await for (final dynamic chunk in chat.generateChatResponseAsync()) {
        String chunkStr = chunk.toString();

        // Extract content between quotes to remove "TextResponse("...")"
        final RegExp regExp = RegExp(r'"(.*?)"');
        final match = regExp.firstMatch(chunkStr);

        if (match != null) {
          String cleanToken = match.group(1) ?? "";
          // Convert literal string escaped characters into actual control characters
          cleanToken = cleanToken
              .replaceAll(r'\n', '\n')
              .replaceAll(r"\'", "'")
              .replaceAll(r'\"', '"');
          responseBuffer.write(cleanToken);
        }
      }

      String result = responseBuffer.toString().trim();

      // ✅ PRODUCTION GUARDRAIL: Find the actual start of data
      // This prevents conversational noise from breaking your parsers.
      int jsonListStart = result.indexOf('[');
      int jsonObjStart = result.indexOf('{');
      int questionLabelStart = result.indexOf('Question:');

      int finalStartIndex = -1;

      // Determine the earliest valid starting point
      if (jsonListStart != -1) finalStartIndex = jsonListStart;
      if (jsonObjStart != -1 &&
          (finalStartIndex == -1 || jsonObjStart < finalStartIndex)) {
        finalStartIndex = jsonObjStart;
      }
      if (questionLabelStart != -1 &&
          (finalStartIndex == -1 || questionLabelStart < finalStartIndex)) {
        finalStartIndex = questionLabelStart;
      }

      if (finalStartIndex != -1) {
        result = result.substring(finalStartIndex);
      }

      _logger
          .d("✅ Generated ${result.length} characters of sanitized content.");
      return result.isNotEmpty ? result : "[]";
    } catch (e) {
      _logger.e("❌ AI Generation Error: $e");
      return "[]";
    }
  }

  /// XAI Logic: Analyzes student errors and provides brief explanations.
  Future<String> explainMistake({
    required String question,
    required String studentAns,
    required String correctAns,
  }) async {
    try {
      final model = await _getOrInstallModel(maxTokens: explanationMaxTokens);
      if (model == null) return "Explanation unavailable offline.";

      final chat = await model.createChat();
      String xaiPrompt = """
Analyze this student error:
Q: "$question"
Student: "$studentAns"
Correct: "$correctAns"
Explain the mistake briefly.
""";

      await chat.addQueryChunk(Message.text(text: xaiPrompt, isUser: true));

      StringBuffer feedback = StringBuffer();
      await for (final dynamic chunk in chat.generateChatResponseAsync()) {
        final match = RegExp(r'"(.*?)"').firstMatch(chunk.toString());
        if (match != null) {
          feedback.write(match.group(1)?.replaceAll(r'\n', '\n') ?? "");
        }
      }

      return feedback.toString().trim();
    } catch (e) {
      _logger.e("❌ XAI Error: $e");
      return "Unable to generate feedback.";
    }
  }
}
