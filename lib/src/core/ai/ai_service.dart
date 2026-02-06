import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logger/logger.dart';

class AIService {
  final Logger _logger = Logger();

  static const int defaultMaxTokens = 256;
  static const int explanationMaxTokens = 128;

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

  /// ✅ Added back: Explain mistake logic for quiz_play_screen.dart
  Future<String> explainMistake({
    required String question,
    required String studentAns,
    required String correctAns,
  }) async {
    try {
      final model =
          await FlutterGemma.getActiveModel(maxTokens: explanationMaxTokens);
      final chat = await model.createChat();

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

  bool isResponseValid(String response) {
    return response.isNotEmpty && response != "[]" && response.length > 5;
  }
}
