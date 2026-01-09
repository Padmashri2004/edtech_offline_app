import 'package:flutter_gemma/flutter_gemma.dart';

class AIService {
  /// GEN AI: Automated Question Paper/Quiz Generation [cite: 25, 84, 120]
  Future<String> generateAssessment({required String prompt, int maxTokens = 3000}) async {
    final model = await FlutterGemma.getActiveModel(maxTokens: maxTokens);
    final chat = await model.createChat();
    
    // Generates content with high-quality distractors [cite: 120]
    await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
    
    StringBuffer response = StringBuffer();
    await for (final chunk in chat.generateChatResponseAsync()) {
      response.write(chunk);
    }
    return response.toString();
  }

  /// XAI: "Explain My Mistake" Logic [cite: 108]
  Future<String> explainMistake({
    required String question, 
    required String studentAns, 
    required String correctAns
  }) async {
    final model = await FlutterGemma.getActiveModel(maxTokens: 512);
    final chat = await model.createChat();

    String xaiPrompt = "Explain reasoning: Question: $question. Student Answer: $studentAns. Correct: $correctAns. Why is it wrong?";

    await chat.addQueryChunk(Message.text(text: xaiPrompt, isUser: true));
    
    StringBuffer feedback = StringBuffer();
    await for (final chunk in chat.generateChatResponseAsync()) {
      feedback.write(chunk);
    }
    return feedback.toString();
  }

  /// AGENTIC AI: Dynamic Deadline Adjustment [cite: 48, 128, 129]
  Future<String> evaluateProgress(String perfData) async {
    final model = await FlutterGemma.getActiveModel(maxTokens: 512);
    final chat = await model.createChat();

    String agentPrompt = "Analyze $perfData. Does student need a deadline extension? [cite: 47, 129]";

    await chat.addQueryChunk(Message.text(text: agentPrompt, isUser: true));
    
    StringBuffer suggestion = StringBuffer();
    await for (final chunk in chat.generateChatResponseAsync()) {
      suggestion.write(chunk);
    }
    return suggestion.toString();
  }
}