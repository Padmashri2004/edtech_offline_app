import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('🔥 AI Service Full Smoke Test - Quiz Mode',
      (WidgetTester tester) async {
    debugPrint('--------------------------------------------------');
    debugPrint('🧪 TEST START: Initializing AI Engine...');

    await FlutterGemma.initialize();
    debugPrint('✅ FlutterGemma Engine Initialized');

    final aiService = AIService();

    debugPrint('⏳ Step 1: Requesting a Structured Quiz Question...');

    // Pattern Matching Prompt: Shows the AI the "Shape" of the response we want
    const String quizPrompt = """
Task: Generate one Multiple Choice Question about the Solar System.

Example:
Question: Which planet is known as the Red Planet?
A) Venus
B) Mars
C) Jupiter
D) Saturn
Correct Answer: B

Now generate a different question:
Question: """;

    // We send the prompt. Note: We include the start of the response ("Question: ")
    // so the AI just has to continue the sentence.
    final response = await aiService.generateAssessment(prompt: quizPrompt);

    // Note: Since the prompt ends with "Question:", the response usually starts
    // immediately with the question text. We'll add the label back in the display.
    final fullOutput = "Question: $response";

    debugPrint('\n📝 CLEAN QUIZ RESPONSE:\n');
    debugPrint(fullOutput);
    debugPrint('\n--------------------------------------------------');

    // Validations
    expect(response, isNot("[]"), reason: "Response should not be empty");
    expect(fullOutput.toLowerCase(), contains("a)"),
        reason: "Should have options");
    expect(fullOutput.toLowerCase(), contains("correct answer:"),
        reason: "Should have answer");

    debugPrint(
        '🎉 TEST PASSED: AI followed the pattern and skipped the small talk!');
  }, timeout: const Timeout(Duration(minutes: 30)));
}
