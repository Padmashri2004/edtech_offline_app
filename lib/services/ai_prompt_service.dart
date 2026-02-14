import 'package:logger/logger.dart';

class AiPromptService {
  final Logger _logger = Logger();

  static const int maxTextLength = 1200;
  static const int recommendedQuestionsPerCall = 3;
  static const int maxPromptTokens = 300;

  /// ✅ ENHANCED: Build section prompt with tier-aware hint logic
  String buildSectionPrompt({
    required String text,
    required String difficulty,
    required String sectionType,
    required int count,
    bool hintsIncluded = false,
    List<String>? focusTopics,
    String? tier, // ✅ NEW: Pass tier to determine hint logic
  }) {
    // Ensure safe text length
    String safeText =
        text.length > maxTextLength ? text.substring(0, maxTextLength) : text;

    String focusContext = '';
    if (focusTopics != null && focusTopics.isNotEmpty) {
      focusContext = '\nFocus on: ${focusTopics.join(", ")}';
    }

    String instructions = "";
    String jsonExample = "";

    switch (sectionType) {
      case 'MCQ':
        instructions =
            "Generate $count Multiple Choice Questions (MCQs) with 4 plausible options and one correct answer.";
        jsonExample =
            '[{"q":"Question?","o":["A","B","C","D"],"a":"Correct Option"}]';
        break;

      case 'Fill-up':
        // ✅ FIXED: Hint logic based on tier
        if (tier == 'Basic') {
          instructions =
              "Generate $count Fill-in-the-blanks. IMPORTANT: Add a helpful (Hint) at the end of the question text.";
        } else {
          instructions =
              "Generate $count Fill-in-the-blanks. NO hints should be provided.";
        }
        jsonExample = '[{"q":"The sky is ____.","o":[],"a":"Blue"}]';
        break;

      case 'True/False':
        instructions = "Generate $count True/False statements.";
        jsonExample = '[{"q":"Statement","o":["True","False"],"a":"True"}]';
        break;

      case 'OddOneOut':
        instructions =
            "Generate $count 'Odd One Out' questions. Provide 4 items where 1 does not belong.";
        jsonExample =
            '[{"q":"Identify the odd one out","o":["Apple","Carrot","Mango","Banana"],"a":"Carrot"}]';
        break;

      case 'Rearrange':
        instructions =
            "Generate $count 'Rearrange' questions. Provide jumbled words/sentences.";
        jsonExample =
            '[{"q":"Rearrange: is / He / boy / a","o":[],"a":"He is a boy"}]';
        break;

      case 'MatchIt':
        instructions =
            "Generate $count matching pairs. Question = Left Item, Answer = Right Match.";
        jsonExample = '[{"q":"Heart","o":[],"a":"Pumps Blood"}]';
        break;

      case 'CaseStudy':
      case 'PictureBased':
        instructions =
            "Write a short Case Study paragraph based on the text. Then ask a question analyzing it. Mention '[Insert Diagram]' if needed.";
        jsonExample =
            '[{"q":"[Case Study Text]... Question?","o":[],"a":"Answer"}]';
        break;

      case 'ShortAns':
        instructions =
            "Generate $count Short Answer questions (2-3 sentences).";
        jsonExample = '[{"q":"Explain...","o":[],"a":"Brief Answer"}]';
        break;

      case 'LongAns':
        instructions =
            "Generate $count Long Answer questions (detailed, 8-10 sentences).";
        jsonExample =
            '[{"q":"Describe in detail...","o":[],"a":"Detailed Answer"}]';
        break;

      default:
        instructions = "Generate $count questions.";
        jsonExample = '[{"q":"...","o":[],"a":"..."}]';
    }

    String prompt = """
Task: $instructions
Difficulty: $difficulty
$focusContext
Context: "$safeText"

OUTPUT JSON ONLY. No Markdown. Format:
$jsonExample
""";

    _logger.d(
        "🔹 Prompt built for section type: $sectionType (Tier: ${tier ?? 'N/A'})");
    return prompt;
  }

  /// ✅ NEW: Build batch prompts for multiple question types
  List<String> buildBatchPrompts({
    required String text,
    required String difficulty,
    required Map<String, int> distribution,
    List<String>? focusTopics,
    String? tier, // ✅ NEW
  }) {
    List<String> prompts = [];

    for (var entry in distribution.entries) {
      String sectionType = entry.key;
      int count = entry.value;

      // Split large counts into smaller batches
      int remaining = count;
      while (remaining > 0) {
        int batchSize = remaining > recommendedQuestionsPerCall
            ? recommendedQuestionsPerCall
            : remaining;

        String prompt = buildSectionPrompt(
          text: text,
          difficulty: difficulty,
          sectionType: sectionType,
          count: batchSize,
          focusTopics: focusTopics,
          tier: tier, // ✅ Pass tier
        );

        prompts.add(prompt);
        remaining -= batchSize;
      }
    }

    _logger.i("📦 Built ${prompts.length} batch prompts");
    return prompts;
  }

  /// Calculate estimated token count
  int estimateTokenCount(String text) {
    return (text.length / 4).ceil();
  }

  /// Chunk large text into manageable pieces
  List<String> chunkText(String text, int maxChunkLength) {
    List<String> chunks = [];
    int start = 0;

    while (start < text.length) {
      int end = start + maxChunkLength;
      if (end > text.length) end = text.length;

      // Try to break at sentence boundary
      if (end < text.length) {
        int lastPeriod = text.lastIndexOf('.', end);
        if (lastPeriod > start) {
          end = lastPeriod + 1;
        }
      }

      chunks.add(text.substring(start, end).trim());
      start = end;
    }

    _logger.d("📄 Split text into ${chunks.length} chunks");
    return chunks;
  }
}
