import 'dart:convert';

class ExamModel {
  final int? id;
  final String title;
  final String difficulty;
  final String timestamp;
  final List<QuestionModel> questions;

  ExamModel({
    this.id,
    required this.title,
    required this.difficulty,
    required this.timestamp,
    required this.questions,
  });

  /// Convert Exam object to Map for Database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'difficulty': difficulty,
      'timestamp': timestamp,
      // We don't store questions in the 'exams' table directly; 
      // they are stored in the 'questions' table linked by ID.
    };
  }

  /// Create Exam object from Database Map
  factory ExamModel.fromMap(Map<String, dynamic> map) {
    return ExamModel(
      id: map['id'],
      title: map['title'],
      difficulty: map['difficulty'],
      timestamp: map['timestamp'],
      questions: [], // Questions are usually loaded via a separate query
    );
  }
}

class QuestionModel {
  final int? id;
  final int? examId;
  final String questionText; // <--- This is the field the PDF service needs
  final dynamic options;     // Can be String (JSON) or List<String>
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
      // FIXED: Checks for 'question' (from AI) OR 'question_text' (from DB)
      questionText: map['question'] ?? map['question_text'] ?? 'No Question Text',
      options: map['options'],
      // FIXED: Checks for 'answer_index' (AI) OR 'correct_answer' (DB)
      correctAnswer: map['answer_index']?.toString() ?? map['correct_answer'] ?? '',
      explanation: map['explanation'],
    );
  }

  /// Convert Question object to Map for Database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam_id': examId,
      'question_text': questionText,
      // Ensure options are stored as a JSON string
      'options': options is List ? jsonEncode(options) : options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
    };
  }
}