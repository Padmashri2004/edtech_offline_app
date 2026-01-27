import 'package:logger/logger.dart';

class AiPromptService {
  final Logger _logger = Logger();

  // FIXED: Optimized for Gemma 3-270M (512 token context window)
  static const int maxTextLength = 1200; // Reduced from 2000
  static const int recommendedQuestionsPerCall = 3; // Reduced from 5
  static const int maxPromptTokens = 300; // Leave 200+ for output

  String buildSectionPrompt({
    required String text,
    required String difficulty,
    required String sectionType,
    required int count,
    bool hintsIncluded = false,
    List<String>? focusTopics,
  }) {
    String safeText =
        text.length > maxTextLength ? text.substring(0, maxTextLength) : text;

    String focusContext = '';
    if (focusTopics != null && focusTopics.isNotEmpty) {
      focusContext = '\nFocus: ${focusTopics.join(", ")}';
    }

    // FIXED: Add difficulty-specific instructions
    String difficultyInstructions = _getDifficultyInstructions(difficulty);

    String prompt = "";

    if (sectionType == 'PictureBased') {
      prompt = """
List $count visual concepts as JSON: [{"topic":"X","answer":"Y"}]
$focusContext
Text: "$safeText"
JSON only:""";
    } else if (sectionType == 'WhoSaidThis') {
      prompt = """
Find $count quotes/laws as JSON: [{"q":"Who said X?","a":"Name"}]
$focusContext
Text: "$safeText"
JSON only:""";
    } else if (sectionType == 'LongAns' || sectionType == 'ShortAns') {
      String ansLength =
          sectionType == 'LongAns' ? '5-7 sentences' : '2-3 sentences';

      prompt = """
Generate $count questions. Answer length: $ansLength.
$difficultyInstructions
$focusContext
Text: "$safeText"
JSON: [{"q":"Explain...","a":"Answer"}]""";
    } else {
      String rules = _getRules(sectionType, hintsIncluded);

      prompt = """
Generate $count $sectionType questions. $difficultyInstructions
$rules
$focusContext
Text: "$safeText"
JSON: [{"q":"...","o":["A","B"],"a":"...","e":"..."}]""";
    }

    _logger.d(
        "🔹 Prompt for $sectionType ($count questions) - ${prompt.length} chars");
    return prompt;
  }

  // NEW: Difficulty-based instruction generation
  String _getDifficultyInstructions(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'basic':
        return 'Use simple language. Focus on recall.';
      case 'medium':
        return 'Use moderate vocabulary. Include application.';
      case 'hard':
      case 'advanced':
        return 'Use advanced terms. Multi-step reasoning.';
      default:
        return '';
    }
  }

  String _getRules(String type, bool hints) {
    switch (type) {
      case 'MCQ':
        return '''4 options. Wrong answers must be plausible and related.
Format: "o":["A","B","C","D"]''';

      case 'Fill-up':
        return hints
            ? '''Blank: _____. Hint in brackets (function/type).
NO letter hints. Format: "o":[]'''
            : '''Blank: _____. No hints. Format: "o":[]''';

      case 'True/False':
        return '''Clear factual statements. Format: "o":["True","False"]''';

      case 'Rearrange':
        return '''Jumbled words forming sentence.
Format: "o":["word","jumbled"],"a":"Correct sentence"''';

      case 'MatchIt':
        return '''Term and definition pairs. Format: "q":"Item A","a":"Match B","o":[]''';

      case 'OddOneOut':
        return '''4 items, 1 different. All plausible.
Format: "o":["Item1","Item2","Item3","Item4"],"a":"Odd item"''';

      default:
        return '"o":[]';
    }
  }

  bool isPromptOptimized(String prompt) {
    return prompt.length < maxPromptTokens * 4 && // ~4 chars per token
        prompt.contains('JSON') &&
        !prompt.contains('complex reasoning');
  }
}
