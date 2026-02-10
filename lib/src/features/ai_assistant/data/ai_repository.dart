import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';

class AIRepository {
  final AIService _aiService = AIService();
  final Logger _logger = Logger();

  // Constants for optimization
  static const int maxContentLength = 1200; // Gemma 270M context limit
  static const int batchSize = 3; // Generate questions in batches

  /// Generate assessment questions using AI (OPTIMIZED)
  Future<List<Map<String, dynamic>>> generateAssessment({
    required String prompt,
    int maxTokens = AIService.defaultMaxTokens,
  }) async {
    try {
      final response = await _aiService.generateAssessment(
        prompt: prompt,
        maxTokens: maxTokens,
      );

      if (!_aiService.isResponseValid(response)) {
        _logger.w("⚠️ Invalid AI response for assessment");
        return [];
      }

      // Parse and validate response
      try {
        final parsed = _parseResponse(response);
        return _validateQuestions(parsed);
      } catch (e) {
        _logger.e("❌ Failed to parse AI response: $e");
        return [];
      }
    } catch (e) {
      _logger.e("❌ Assessment generation error: $e");
      return [];
    }
  }

  /// OPTIMIZED: Generate questions in batches to reduce AI calls
  Future<List<Map<String, dynamic>>> generateQuestionsOptimized({
    required String rawContent,
    required String difficulty,
    required List<Map<String, dynamic>> questionTypes,
    void Function(double progress)? onProgress,
  }) async {
    List<Map<String, dynamic>> allQuestions = [];
    
    // Chunk content for better processing
    final chunks = _chunkContent(rawContent);
    final bestChunk = chunks.isNotEmpty ? chunks.first : rawContent;
    
    // Calculate total batches
    int totalBatches = (questionTypes.length / batchSize).ceil();
    int processedBatches = 0;
    
    // Process question types in batches
    for (int i = 0; i < questionTypes.length; i += batchSize) {
      final endIdx = (i + batchSize < questionTypes.length) 
          ? i + batchSize 
          : questionTypes.length;
      final batch = questionTypes.sublist(i, endIdx);
      
      // Build batch prompt
      final batchPrompt = _buildBatchPrompt(bestChunk, difficulty, batch);
      
      // Generate questions for this batch
      final batchQuestions = await generateAssessment(
        prompt: batchPrompt,
        maxTokens: AIService.defaultMaxTokens,
      );
      
      // Assign correct marks to each question
      for (var q in batchQuestions) {
        final qType = q['type'] ?? '';
        final matchingType = batch.firstWhere(
          (t) => t['type'] == qType,
          orElse: () => batch.first,
        );
        q['marks'] = matchingType['marks'] ?? 1;
      }
      
      allQuestions.addAll(batchQuestions);
      
      processedBatches++;
      onProgress?.call(processedBatches / totalBatches);
    }
    
    _logger.i("✅ Generated ${allQuestions.length} questions in $processedBatches batches");
    return allQuestions;
  }

  /// Build optimized batch prompt for multiple question types
  String _buildBatchPrompt(
    String content,
    String difficulty,
    List<Map<String, dynamic>> types,
  ) {
    final typeRequests = types.map((t) {
      return "${t['count']} ${t['type']} questions (${t['marks']} marks each)";
    }).join(", ");
    
    return """
Generate these questions from the content below:
$typeRequests

Difficulty: $difficulty
Content: ${content.substring(0, content.length > maxContentLength ? maxContentLength : content.length)}

Return ONLY a JSON array with objects containing:
- type (question type)
- question (question text)
- options (array for MCQ/True-False, empty for others)
- correct (correct answer)
- explanation (brief explanation)

Example: [{"type":"MCQ","question":"What is...?","options":["A","B","C","D"],"correct":"A","explanation":"..."}]
""";
  }

  /// Chunk content into manageable pieces for Gemma 270M
  List<String> _chunkContent(String content) {
    List<String> chunks = [];
    
    if (content.length <= maxContentLength) {
      return [content];
    }
    
    // Split by paragraphs first
    final paragraphs = content.split('\n\n');
    StringBuffer currentChunk = StringBuffer();
    
    for (var para in paragraphs) {
      if (currentChunk.length + para.length > maxContentLength) {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.toString());
          currentChunk.clear();
        }
        
        // If single paragraph is too long, split by sentences
        if (para.length > maxContentLength) {
          final sentences = para.split('. ');
          for (var sentence in sentences) {
            if (currentChunk.length + sentence.length > maxContentLength) {
              if (currentChunk.isNotEmpty) {
                chunks.add(currentChunk.toString());
                currentChunk.clear();
              }
            }
            currentChunk.write(sentence);
            currentChunk.write('. ');
          }
        } else {
          currentChunk.write(para);
        }
      } else {
        currentChunk.write(para);
        currentChunk.write('\n\n');
      }
    }
    
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.toString());
    }
    
    return chunks.where((c) => c.trim().isNotEmpty).toList();
  }

  /// Validate and clean questions
  List<Map<String, dynamic>> _validateQuestions(List<Map<String, dynamic>> questions) {
    List<Map<String, dynamic>> validated = [];
    
    for (var q in questions) {
      // Must have question text
      if (q['question'] == null || q['question'].toString().trim().isEmpty) {
        continue;
      }
      
      // Must have correct answer
      if (q['correct'] == null || q['correct'].toString().trim().isEmpty) {
        if (q['answer'] != null) {
          q['correct'] = q['answer'];
        } else {
          continue;
        }
      }
      
      // Ensure options is a list
      if (q['options'] != null && q['options'] is! List) {
        q['options'] = [];
      }
      
      // Set default values
      q['explanation'] ??= '';
      q['marks'] ??= 1;
      q['type'] ??= 'MCQ';
      
      validated.add(q);
    }
    
    return validated;
  }

  /// Explain mistakes in student answers
  Future<String> explainMistake({
    required String question,
    required String studentAns,
    required String correctAns,
  }) async {
    try {
      final response = await _aiService.explainMistake(
        question: question,
        studentAns: studentAns,
        correctAns: correctAns,
      );
      return response;
    } catch (e) {
      _logger.e("❌ Mistake explanation error: $e");
      return "Unable to generate explanation at this time.";
    }
  }

  /// Internal helper: parse AI JSON-like response into structured list
  List<Map<String, dynamic>> _parseResponse(String response) {
    try {
      String cleaned = response.trim();
      
      // Remove markdown code blocks if present
      cleaned = cleaned.replaceAll(RegExp(r'```json\s*'), '');
      cleaned = cleaned.replaceAll(RegExp(r'```\s*'), '');
      
      // Ensure starts with [ and ends with ]
      if (!cleaned.startsWith("[")) {
        // Try to find JSON array in response
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(cleaned);
        if (jsonMatch != null) {
          cleaned = jsonMatch.group(0)!;
        } else {
          cleaned = "[$cleaned]";
        }
      }
      
      final decoded = jsonDecode(cleaned);
      
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      } else {
        _logger.w("⚠️ Response not a list, returning empty");
        return [];
      }
    } catch (e) {
      _logger.w("⚠️ Response not valid JSON: $e");
      // Try to extract individual JSON objects
      return _tryExtractJsonObjects(response);
    }
  }

  /// Try to extract individual JSON objects from malformed response
  List<Map<String, dynamic>> _tryExtractJsonObjects(String response) {
    List<Map<String, dynamic>> objects = [];
    
    try {
      // Find all {...} patterns
      final objectMatches = RegExp(r'\{[^{}]*\}').allMatches(response);
      
      for (var match in objectMatches) {
        try {
          final obj = jsonDecode(match.group(0)!);
          if (obj is Map<String, dynamic>) {
            objects.add(obj);
          }
        } catch (_) {
          // Skip invalid objects
        }
      }
    } catch (e) {
      _logger.e("❌ Could not extract JSON objects: $e");
    }
    
    return objects;
  }
}