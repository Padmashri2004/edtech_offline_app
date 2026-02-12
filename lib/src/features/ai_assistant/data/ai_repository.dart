import 'dart:convert';
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:logger/logger.dart';

class AIRepository {
  final AIService _aiService = AIService();
  final Logger _logger = Logger();

  Future<QuestionModel?> generateQuestion({
    required String type,
    required String difficulty,
    required String topic,
    required int marks,
  }) async {
    try {
      final prompt = _buildQuestionPrompt(
        type: type,
        difficulty: difficulty,
        topic: topic,
        marks: marks,
      );

      final response = await _aiService.generateAssessment(prompt: prompt);
      return _parseQuestionFromResponse(response, type, marks);
    } catch (e) {
      _logger.e('Error generating question: $e');
      return null;
    }
  }

  String _buildQuestionPrompt({
    required String type,
    required String difficulty,
    required String topic,
    required int marks,
  }) {
    String instructions = '';
    String jsonExample = '';

    switch (type) {
      case 'MCQ':
        instructions = 'Generate a Multiple Choice Question with 4 options.';
        jsonExample =
            '{"q":"Question?","o":["A","B","C","D"],"a":"Correct Option"}';
        break;
      case 'Fill-up':
        instructions = 'Generate a Fill-in-the-blank question.';
        jsonExample = '{"q":"The sky is ____.","o":[],"a":"blue"}';
        break;
      case 'True/False':
        instructions = 'Generate a True/False statement.';
        jsonExample = '{"q":"Statement","o":["True","False"],"a":"True"}';
        break;
      case 'OddOneOut':
        instructions = 'Generate an Odd One Out question with 4 items.';
        jsonExample =
            '{"q":"Identify the odd one","o":["Apple","Carrot","Mango","Banana"],"a":"Carrot"}';
        break;
      // ✅ ADDED: Case Study support for Module 6 Advanced Tier
      case 'CaseStudy':
        instructions =
            'Provide a short educational paragraph (Case Study) and one analytical question based on it.';
        jsonExample =
            '{"q":"[Paragraph...] Question?","o":[],"a":"Detailed Answer"}';
        break;
      case 'ShortAns':
        instructions = 'Generate a Short Answer question (2-3 sentences).';
        jsonExample = '{"q":"Explain...","o":[],"a":"Brief answer"}';
        break;
      case 'LongAns':
        instructions = 'Generate a Long Answer question (detailed analysis).';
        jsonExample =
            '{"q":"Describe in detail...","o":[],"a":"Detailed answer"}';
        break;
      default:
        instructions = 'Generate a question.';
        jsonExample = '{"q":"Question?","o":[],"a":"Answer"}';
    }

    return '''
Task: $instructions
Topic: $topic
Difficulty: $difficulty
Marks: $marks

Return ONLY valid JSON:
$jsonExample
''';
  }

  QuestionModel? _parseQuestionFromResponse(
      String response, String type, int marks) {
    try {
      String cleaned = response.trim();
      // Remove common Markdown clutter
      cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '').trim();

      final json = jsonDecode(cleaned);
      return QuestionModel(
        questionText: json['q'] as String,
        type: type,
        options: (json['o'] as List?)?.cast<String>() ?? [],
        correctAnswer: json['a'] as String,
        marks: marks,
        explanation: json['explanation'] ?? '',
      );
    } catch (e) {
      _logger.e('JSON Parse Error: $e. Content: $response');
      return null;
    }
  }

  Future<String> generateText(String prompt) async =>
      await _aiService.generateAssessment(prompt: prompt);
}
