import 'package:logger/logger.dart';

class AiPromptService {
  final Logger _logger = Logger();

  /// Generates the prompt based on level, content, question type AND focused topics.
  /// Optimized for Gemma 270M (Nano) using One-Shot Prompting.
  String buildSectionPrompt({
    required String text,
    required String difficulty, // 'Basic' or 'Advanced'
    required String sectionType,
    required int count,
    bool hintsIncluded = false, // For Basic Fill-ups
    List<String>? focusTopics, // NEW: Focus on specific topics
  }) {
    String typeRules = _getRulesForType(sectionType, hintsIncluded);
    String jsonExample = _getExampleForType(sectionType);

    // Truncate text to avoid memory overflow (Safe limit for Nano model)
    String safeText = text.length > 2000 ? text.substring(0, 2000) : text;

    // Construct the Topic Focus string if topics are provided
    String topicInstruction = "";
    if (focusTopics != null && focusTopics.isNotEmpty) {
      topicInstruction =
          "FOCUS specifically on these concepts: ${focusTopics.join(', ')}.";
    }

    String prompt = """
Analyze the text and generate $count "$sectionType" questions.
Difficulty: $difficulty.
$topicInstruction
RULES:
1. OUTPUT ONLY A RAW JSON ARRAY. No markdown.
2. $typeRules

EXAMPLE JSON FORMAT:
$jsonExample

CONTENT:
"$safeText"

GENERATE JSON:
""";

    _logger.d("Prompt for $sectionType: $prompt");
    return prompt;
  }

  String _getRulesForType(String type, bool hints) {
    switch (type) {
      case 'MCQ':
        return 'Create 4 options. "answer_index" (0-3). Include plausible distractors.';
      case 'Fill-up':
        return hints
            ? 'Question must have "_______". Provide a hint in brackets at the end. Put answer in "correct_answer".'
            : 'Question must have "_______". NO hints. Put answer in "correct_answer".';
      case 'True/False':
        return 'Options must be ["True", "False"]. Answer index 0 for True, 1 for False.';
      case 'OddOneOut':
        return 'Provide 4 options in "options". One is different. Explain why in "explanation".';
      case 'Rearrange':
        return 'Provide a jumbled sentence as a List of strings in "options". Put the correct full sentence in "correct_answer".';
      case 'MatchIt':
        return 'Generate a pair. Put Column A item in "question" and Column B match in "correct_answer". Ignore options.';
      case 'AssertionReason':
        return 'Format: Question = "Assertion: [A]... Reason: [R]...". Options=["A & R true, R explains A", "A & R true, but R does not explain", "A true, R false", "A false, R true"]. Answer index 0-3.';
      case 'ShortAns':
      case 'LongAns':
        return 'Generate valid academic questions. Leave "options" empty []. Provide key points in "correct_answer".';
      case 'CaseStudy':
        // CRITICAL FIX: Put both Scenario and Question in the 'question' field so PDF sees it.
        return 'Generate a short scenario (3 sentences) followed immediately by a specific question based on it. Put the ENTIRE text (Scenario + Question) in "question". Put the answer key in "explanation".';
      default:
        return 'Standard question format. Put answer in "correct_answer".';
    }
  }

  String _getExampleForType(String type) {
    if (type == 'MCQ' || type == 'OddOneOut') {
      return '[{"question": "Sample Q?", "options": ["A","B","C","D"], "answer_index": 0, "correct_answer": "A", "explanation": "..."}]';
    } else if (type == 'MatchIt') {
      return '[{"question": "Photosynthesis", "correct_answer": "Chlorophyll", "options": [], "answer_index": 0}]';
    } else if (type == 'Rearrange') {
      return '[{"question": "Rearrange words", "options": ["is", "Blue", "sky"], "correct_answer": "Blue is sky", "answer_index": 0}]';
    } else if (type == 'AssertionReason') {
      return '[{"question": "Assertion: X. Reason: Y.", "options": ["A&R True...", "A&R False..."], "answer_index": 0, "correct_answer": "A&R True..."}]';
    } else if (type == 'Fill-up') {
      return '[{"question": "The sky is _______.", "correct_answer": "Blue", "options": [], "answer_index": 0}]';
    }
    // Default for Text answers
    return '[{"question": "Explain X?", "options": [], "correct_answer": "X is...", "explanation": "..."}]';
  }
}
