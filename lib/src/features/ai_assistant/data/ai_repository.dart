import 'dart:convert';
import 'package:edtech_offline_app/src/core/ai/ai_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:logger/logger.dart';

class AIRepository {
  final AIService _aiService = AIService();
  final Logger _logger = Logger();

  // ✅ Generate single question
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

      _logger.d('Generating $type question about $topic');

      final response = await _aiService.generateAssessment(prompt: prompt);

      return _parseQuestionFromResponse(response, type, marks);
    } catch (e) {
      _logger.e('Error generating question: $e');
      return null;
    }
  }

  // ✅ Generate multiple questions
  Future<List<QuestionModel>> generateQuestions({
    required String type,
    required String difficulty,
    required String topic,
    required int count,
    required int marksPerQuestion,
  }) async {
    final questions = <QuestionModel>[];

    for (int i = 0; i < count; i++) {
      final question = await generateQuestion(
        type: type,
        difficulty: difficulty,
        topic: topic,
        marks: marksPerQuestion,
      );

      if (question != null) {
        questions.add(question);
      }

      // Small delay to avoid overwhelming the AI
      await Future.delayed(const Duration(milliseconds: 200));
    }

    return questions;
  }

  // Build prompt for question generation
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
      case 'ShortAns':
        instructions =
            'Generate a Short Answer question (2-3 sentences answer).';
        jsonExample = '{"q":"Explain...","o":[],"a":"Brief answer"}';
        break;
      case 'LongAns':
        instructions = 'Generate a Long Answer question (detailed answer).';
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

Return ONLY valid JSON (no markdown, no explanation):
$jsonExample
''';
  }

  // Parse AI response to QuestionModel
  QuestionModel? _parseQuestionFromResponse(
      String response, String type, int marks) {
    try {
      String cleaned = response.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final json = jsonDecode(cleaned);

      return QuestionModel(
        questionText: json['q'] as String,
        type: type,
        options: (json['o'] as List?)?.cast<String>() ?? [],
        correctAnswer: json['a'] as String,
        marks: marks,
        explanation: '',
      );
    } catch (e) {
      _logger.e('Error parsing question response: $e');
      _logger.e('Response was: $response');
      return null;
    }
  }

  // General purpose AI call
  Future<String> generateText(String prompt) async {
    return await _aiService.generateAssessment(prompt: prompt);
  }

  // Check if AI is initialized
  Future<bool> isInitialized() async {
    try {
      final response =
          await _aiService.generateAssessment(prompt: 'Test prompt');
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
