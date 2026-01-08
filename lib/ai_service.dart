import 'package:flutter_gemma/flutter_gemma.dart';

class AIService {
  /// Generates a 100-mark exam using the session-based API.
  Future<String> generate100MarkExam({required String topic, required String tier}) async {
    // 1. Get the Model (Guaranteed non-null in v0.12.0)
    final model = await FlutterGemma.getActiveModel(maxTokens: 2048);

    // 2. Create the Chat Session
    final chatSession = await model.createChat();

    // Marking scheme pattern
    String pattern = (tier == 'Basic') 
      ? "BASIC: 5 MCQs, 5 Fill-ups, 5 Match, 5 Rearrange, 5 Odd-one, 7 Short, 7 Long [100m]"
      : "ADVANCED: 5 MS-MCQs, 5 Fill-ups, 5 Correct-stmt, 1 Summary, 3 Assertion, 2 T/F, 7 Short, 7 Long [100m]";

    String finalPrompt = "Generate $topic exam JSON. Pattern: $pattern. Return ONLY JSON.";

    // 3. Process the query
    await chatSession.addQueryChunk(Message.text(text: finalPrompt, isUser: true));
    
    // 4. Collect response (Standard streaming procedure)
    StringBuffer responseText = StringBuffer();
    await for (final chunk in chatSession.generateChatResponseAsync()) {
      responseText.write(chunk);
    }

    // Optional: Close session to free memory
    // await chatSession.close();

    return responseText.toString();
  }
}