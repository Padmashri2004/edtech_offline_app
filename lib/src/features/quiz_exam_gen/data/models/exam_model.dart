import 'dart:convert';

class ExamModel {
  final int? id;
  final String title;
  final String difficulty;
  final String timestamp;
  final int timerMinutes;
  final List<String> assignedStudents; // NEW: Track who this exam is for
  final List<QuestionModel> questions;

  ExamModel({
    this.id,
    required this.title,
    required this.difficulty,
    required this.timestamp,
    this.timerMinutes = 30,
    this.assignedStudents = const [], // Default to empty (open for all)
    required this.questions,
  });

  /// Convert Exam object to Map for Database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'difficulty': difficulty,
      'timestamp': timestamp,
      'timer_minutes': timerMinutes,
      // Store list as JSON string
      'assigned_students': jsonEncode(assignedStudents),
    };
  }

  /// Create Exam object from Database Map
  factory ExamModel.fromMap(Map<String, dynamic> map) {
    // Parse assigned_students safely
    List<String> students = [];
    if (map['assigned_students'] != null) {
      try {
        students = List<String>.from(jsonDecode(map['assigned_students']));
      } catch (e) {
        // Fallback if parsing fails
      }
    }

    return ExamModel(
      id: map['id'],
      title: map['title'],
      difficulty: map['difficulty'],
      timestamp: map['timestamp'],
      timerMinutes: map['timer_minutes'] ?? 30,
      assignedStudents: students,
      questions: [], // Questions loaded separately
    );
  }
}

class QuestionModel {
  final int? id;
  final int? examId;
  final String questionText;
  final dynamic options;
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

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      questionText:
          map['question'] ?? map['question_text'] ?? 'No Question Text',
      options: map['options'],
      correctAnswer:
          map['answer_index']?.toString() ?? map['correct_answer'] ?? '',
      explanation: map['explanation'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam_id': examId,
      'question_text': questionText,
      'options': options is List ? jsonEncode(options) : options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
    };
  }
}
