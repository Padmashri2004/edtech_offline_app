import 'dart:convert';

class ExamModel {
  final int? id;
  final String title;
  final String difficulty;
  final String timestamp;
  final int timerMinutes; // Added field
  final List<QuestionModel> questions;

  ExamModel({
    this.id,
    required this.title,
    required this.difficulty,
    required this.timestamp,
    this.timerMinutes = 30, // Default to 30 mins
    required this.questions,
  });

  /// Convert Exam object to Map for Database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'difficulty': difficulty,
      'timestamp': timestamp,
      'timer_minutes': timerMinutes, // Map to DB column
    };
  }

  /// Create Exam object from Database Map
  factory ExamModel.fromMap(Map<String, dynamic> map) {
    return ExamModel(
      id: map['id'],
      title: map['title'],
      difficulty: map['difficulty'],
      timestamp: map['timestamp'],
      timerMinutes: map['timer_minutes'] ?? 30, // Retrieve from DB
      questions: [], // Questions are loaded via a separate query
    );
  }
}

class QuestionModel {
  final int? id;
  final int? examId;
  final String questionText;
  final dynamic options; // Can be String (JSON) or List<String>
  final String correctAnswer;
  final String? explanation;

  QuestionModel({
    this.id,
    this.examId,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.explanation,
  });

  /// Create Question object from AI Response (JSON) or Database Map
  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      // Checks for 'question' (from AI) OR 'question_text' (from DB)
      questionText:
          map['question'] ?? map['question_text'] ?? 'No Question Text',
      options: map['options'],
      // Checks for 'answer_index' (AI) OR 'correct_answer' (DB)
      correctAnswer:
          map['answer_index']?.toString() ?? map['correct_answer'] ?? '',
      explanation: map['explanation'],
    );
  }

  /// Convert Question object to Map for Database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam_id': examId,
      'question_text': questionText,
      // Ensure options are stored as a JSON string if they are a list
      'options': options is List ? jsonEncode(options) : options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
    };
  }
}
