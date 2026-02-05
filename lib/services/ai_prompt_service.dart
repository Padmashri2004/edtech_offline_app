import 'package:logger/logger.dart';

class AiPromptService {
  final Logger _logger = Logger();

  // Optimized for Gemma 3-270M
  static const int maxTextLength = 1200;
  static const int recommendedQuestionsPerCall = 3;
  static const int maxPromptTokens = 300;

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
      focusContext = '\nFocus on: ${focusTopics.join(", ")}';
    }

    String instructions = "";
    String jsonExample = "";

    switch (sectionType) {
      case 'MCQ':
        instructions =
            "Generate $count Multiple Choice Questions (MCQs) with 4 options.";
        jsonExample =
            '[{"q":"Question?","o":["A","B","C","D"],"a":"Correct Option"}]';
        break;

      case 'Fill-up':
        if (hintsIncluded) {
          instructions =
              "Generate $count Fill-in-the-blanks. IMPORTANT: Add a (Hint) at the end of the question text.";
        } else {
          instructions = "Generate $count Fill-in-the-blanks. No hints.";
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
      case 'PictureBased': // Handling PictureBased as Case Study text for now
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
        instructions = "Generate $count Long Answer questions (detailed).";
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

    _logger.d("🔹 Prompt: $sectionType");
    return prompt;
  }
}
