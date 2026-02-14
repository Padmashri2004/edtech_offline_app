import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logger/logger.dart';

class AIService {
  final Logger _logger = Logger();

  // ✅ OPTIMIZED: Conservative limits with intelligent chunking
  static const int safeMaxTokens = 384;
  static const int chunkSizeWords = 250;
  static const int explanationMaxTokens = 256;

  // ✅ Buffer for multi-chunk processing
  final List<Map<String, dynamic>> _generatedQuestionsBuffer = [];

  /// Ensures the Gemma 270M model is initialized
  Future<dynamic> _getOrInstallModel({int maxTokens = safeMaxTokens}) async {
    try {
      var model = await FlutterGemma.getActiveModel(maxTokens: maxTokens);
      return model;
    } catch (e) {
      _logger.w("⚠️ No active model found. Initializing Gemma...");
      try {
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
        ).fromAsset("assets/models/gemma.task").install();
        return await FlutterGemma.getActiveModel(maxTokens: maxTokens);
      } catch (installError) {
        _logger.e("❌ Failed to install Gemma: $installError");
        return null;
      }
    }
  }

  /// ✅ ENHANCED: Generate with sentence-aware chunking
  Future<String> generateAssessment({
    required String prompt,
    int maxTokens = safeMaxTokens,
  }) async {
    try {
      final model = await _getOrInstallModel(maxTokens: maxTokens);
      if (model == null) return "[]";

      final chat = await model.createChat();
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

      StringBuffer responseBuffer = StringBuffer();
      int wordCount = 0;

      await for (final dynamic chunk in chat.generateChatResponseAsync()) {
        String chunkStr = chunk.toString();

        // ✅ FIXED: Proper regex pattern with escaped quotes
        final RegExp regExp = RegExp(r'"(.*?)"');
        final match = regExp.firstMatch(chunkStr);

        if (match != null) {
          String cleanToken = match.group(1) ?? "";

          // ✅ FIXED: Single replaceAll calls with proper syntax
          cleanToken = cleanToken.replaceAll(r'\n', '\n');
          cleanToken = cleanToken.replaceAll(r"\'", "'");
          cleanToken = cleanToken.replaceAll(r'\"', '"');

          responseBuffer.write(cleanToken);
          wordCount += cleanToken.split(RegExp(r'\s+')).length;

          // Strategic checkpoint to prevent suspension
          if (wordCount >= chunkSizeWords) {
            _logger.d('📦 Processing checkpoint at $wordCount words...');
            await Future.delayed(const Duration(milliseconds: 100));
            wordCount = 0;
          }
        }
      }

      String result = responseBuffer.toString().trim();

      // Extract JSON data
      int jsonListStart = result.indexOf('[');
      int jsonObjStart = result.indexOf('{');
      int finalStartIndex = -1;

      if (jsonListStart != -1) finalStartIndex = jsonListStart;
      if (jsonObjStart != -1 &&
          (finalStartIndex == -1 || jsonObjStart < finalStartIndex)) {
        finalStartIndex = jsonObjStart;
      }

      if (finalStartIndex != -1) {
        result = result.substring(finalStartIndex);
      }

      _logger.d("✅ Generated ${result.length} characters");
      return result.isNotEmpty ? result : "[]";
    } catch (e) {
      _logger.e("❌ AI Generation Error: $e");
      return "[]";
    }
  }

  /// ✅ NEW: Smart batch generation with content rotation
  Future<List<Map<String, dynamic>>> generateMultipleQuestionsFromChunks({
    required String fullText,
    required String questionType,
    required String difficulty,
    required int totalCount,
    required int marksPerQuestion,
    Function(int, int)? onProgress,
  }) async {
    List<Map<String, dynamic>> allQuestions = [];

    // Split text into sentence-aware chunks
    final chunks = _smartChunkText(fullText, chunkSizeWords);
    _logger.i('📄 Split content into ${chunks.length} chunks');

    int questionsPerChunk = (totalCount / chunks.length).ceil();
    int generated = 0;

    // Generate from each chunk
    for (int i = 0; i < chunks.length && generated < totalCount; i++) {
      int remaining = totalCount - generated;
      int toGenerate =
          remaining > questionsPerChunk ? questionsPerChunk : remaining;

      String prompt = _buildSmartPrompt(
        context: chunks[i],
        questionType: questionType,
        difficulty: difficulty,
        count: toGenerate,
        marks: marksPerQuestion,
      );

      try {
        String response = await generateAssessment(prompt: prompt);
        List<Map<String, dynamic>> parsed = _parseQuestions(response);

        allQuestions.addAll(parsed);
        generated += parsed.length;

        onProgress?.call(generated, totalCount);

        // Delay between chunks
        if (i < chunks.length - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      } catch (e) {
        _logger.e('❌ Error generating from chunk $i: $e');
      }
    }

    return allQuestions;
  }

  /// ✅ CRITICAL: Sentence-aware chunking (prevents word splitting)
  List<String> _smartChunkText(String text, int maxWords) {
    List<String> chunks = [];
    List<String> sentences = _splitIntoSentences(text);

    StringBuffer currentChunk = StringBuffer();
    int currentWordCount = 0;

    for (String sentence in sentences) {
      int sentenceWords = sentence.split(RegExp(r'\s+')).length;

      // If adding this sentence exceeds limit, save current chunk
      if (currentWordCount + sentenceWords > maxWords && currentWordCount > 0) {
        chunks.add(currentChunk.toString().trim());
        currentChunk.clear();
        currentWordCount = 0;
      }

      currentChunk.write(sentence);
      currentChunk.write(' ');
      currentWordCount += sentenceWords;
    }

    // Add remaining content
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.toString().trim());
    }

    return chunks.where((c) => c.isNotEmpty).toList();
  }

  /// ✅ Split text into sentences (respects abbreviations)
  List<String> _splitIntoSentences(String text) {
    // ✅ FIXED: Proper string replacement syntax
    String processed = text;
    processed = processed.replaceAll('Dr.', 'Dr<dot>');
    processed = processed.replaceAll('Mr.', 'Mr<dot>');
    processed = processed.replaceAll('Mrs.', 'Mrs<dot>');
    processed = processed.replaceAll('Ms.', 'Ms<dot>');
    processed = processed.replaceAll('Sr.', 'Sr<dot>');
    processed = processed.replaceAll('Jr.', 'Jr<dot>');
    processed = processed.replaceAll('etc.', 'etc<dot>');
    processed = processed.replaceAll('Fig.', 'Fig<dot>');
    processed = processed.replaceAll('e.g.', 'e<dot>g<dot>');
    processed = processed.replaceAll('i.e.', 'i<dot>e<dot>');

    // Split on sentence boundaries
    List<String> sentences = processed
        .split(RegExp(r'(?<=[.!?])\s+(?=[A-Z])'))
        .map((s) => s.replaceAll('<dot>', '.').trim())
        .where((s) => s.isNotEmpty && s.length > 10)
        .toList();

    return sentences;
  }

  /// ✅ Build optimized prompt
  String _buildSmartPrompt({
    required String context,
    required String questionType,
    required String difficulty,
    required int count,
    required int marks,
  }) {
    String instructions = "";
    String jsonExample = "";

    switch (questionType) {
      case 'MCQ':
        instructions = "Generate $count MCQ with 4 options";
        jsonExample = '[{"q":"Q?","o":["A","B","C","D"],"a":"B"}]';
        break;
      case 'Fill-up':
        instructions = "Generate $count fill-in-blank";
        jsonExample = '[{"q":"Sky is ___","o":[],"a":"blue"}]';
        break;
      case 'True/False':
        instructions = "Generate $count true/false";
        jsonExample =
            '[{"q":"Water boils at 100C","o":["True","False"],"a":"True"}]';
        break;
      case 'ShortAns':
        instructions = "Generate $count short answer (2-3 lines)";
        jsonExample = '[{"q":"Explain?","o":[],"a":"Brief answer"}]';
        break;
      case 'LongAns':
        instructions = "Generate $count detailed answer (5-8 lines)";
        jsonExample = '[{"q":"Describe?","o":[],"a":"Detailed answer"}]';
        break;
      default:
        instructions = "Generate $count questions";
        jsonExample = '[{"q":"?","o":[],"a":"ans"}]';
    }

    return """
$instructions from this content.
Difficulty: $difficulty
Marks: $marks each

"$context"

Output ONLY JSON:
$jsonExample
""";
  }

  /// ✅ Parse questions from response
  List<Map<String, dynamic>> _parseQuestions(String response) {
    try {
      // Remove markdown
      String cleaned = response;
      cleaned = cleaned.replaceAll('```json', '');
      cleaned = cleaned.replaceAll('```', '');
      cleaned = cleaned.trim();

      // Find JSON array
      int start = cleaned.indexOf('[');
      int end = cleaned.lastIndexOf(']');

      if (start != -1 && end != -1 && end > start) {
        cleaned = cleaned.substring(start, end + 1);
      }

      // Parse
      final dynamic parsed = _tryParseJson(cleaned);

      if (parsed is List) {
        return parsed.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      _logger.e('Parse error: $e');
    }

    return [];
  }

  /// ✅ Safe JSON parsing
  dynamic _tryParseJson(String str) {
    try {
      if (str.startsWith('[') && str.endsWith(']')) {
        List<Map<String, dynamic>> result = [];

        // Split by objects
        List<String> objects = str
            .substring(1, str.length - 1)
            .split(RegExp(r'\},\s*\{'))
            .map((s) {
          if (!s.startsWith('{')) s = '{$s';
          if (!s.endsWith('}')) s = '$s}';
          return s;
        }).toList();

        for (String obj in objects) {
          Map<String, dynamic> parsed = _parseJsonObject(obj);
          if (parsed.isNotEmpty) result.add(parsed);
        }

        return result;
      }
    } catch (e) {
      _logger.e('JSON parse failed: $e');
    }
    return [];
  }

  /// ✅ Parse single JSON object
  Map<String, dynamic> _parseJsonObject(String obj) {
    Map<String, dynamic> result = {};
    try {
      // Extract key-value pairs
      RegExp kvPattern = RegExp(r'"(\w+)"\s*:\s*"([^"]*)"');
      RegExp arrayPattern = RegExp(r'"(\w+)"\s*:\s*\[([^\]]*)\]');

      // String values
      for (Match m in kvPattern.allMatches(obj)) {
        result[m.group(1)!] = m.group(2)!;
      }

      // Array values
      for (Match m in arrayPattern.allMatches(obj)) {
        String key = m.group(1)!;
        String arrayContent = m.group(2)!;
        List<String> items = arrayContent
            .split(',')
            .map((s) => s.trim().replaceAll('"', ''))
            .where((s) => s.isNotEmpty)
            .toList();
        result[key] = items;
      }
    } catch (e) {
      _logger.e('Object parse error: $e');
    }
    return result;
  }

  /// XAI explanations
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
Q: "$question"
Student: "$studentAns"
Correct: "$correctAns"
Explain mistake briefly.
""";

      await chat.addQueryChunk(Message.text(text: xaiPrompt, isUser: true));

      StringBuffer feedback = StringBuffer();
      await for (final dynamic chunk in chat.generateChatResponseAsync()) {
        final match = RegExp(r'"(.*?)"').firstMatch(chunk.toString());
        if (match != null) {
          String part = match.group(1) ?? "";
          part = part.replaceAll(r'\n', '\n');
          feedback.write(part);
        }
      }

      return feedback.toString().trim();
    } catch (e) {
      _logger.e("❌ XAI Error: $e");
      return "Unable to generate feedback.";
    }
  }

  /// Clear buffers
  void clearBuffer() {
    _generatedQuestionsBuffer.clear();
    _logger.d("🗑️ Buffer cleared");
  }
}
