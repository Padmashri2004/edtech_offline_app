// C:\Users\Admin\edtech_offline_app\lib\src\features\quiz_exam_gen\data\models\exam_model.dart

import 'dart:convert';

class ExamModel {
  final int? id;
  final String title;
  final String difficulty;
  final String timestamp;
  final int timerMinutes;
  final List<String> assignedStudents;
  final List<QuestionModel> questions;

  ExamModel({
    this.id,
    required this.title,
    required this.difficulty,
    required this.timestamp,
    this.timerMinutes = 30,
    this.assignedStudents = const [],
    required this.questions,
  });

  int get totalMarks => questions.fold(0, (sum, q) => sum + q.marks);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'difficulty': difficulty,
      'timestamp': timestamp,
      'timer_minutes': timerMinutes,
      'assigned_students': jsonEncode(assignedStudents),
    };
  }

  factory ExamModel.fromMap(Map<String, dynamic> map) {
    List<String> students = [];
    if (map['assigned_students'] != null) {
      try {
        students = List<String>.from(jsonDecode(map['assigned_students']));
      } catch (e) {/* ignore */}
    }
    return ExamModel(
      id: map['id'],
      title: map['title'],
      difficulty: map['difficulty'],
      timestamp: map['timestamp'],
      timerMinutes: map['timer_minutes'] ?? 30,
      assignedStudents: students,
      questions: [],
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
  final int marks;
  final String? imagePath; // ✅ ADDED THIS FIELD

  QuestionModel({
    this.id,
    this.examId,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.marks = 1,
    this.imagePath, // ✅ ADDED TO CONSTRUCTOR
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      questionText:
          map['question'] ?? map['question_text'] ?? 'No Question Text',
      options: map['options'],
      correctAnswer:
          map['answer_index']?.toString() ?? map['correct_answer'] ?? '',
      explanation: map['explanation'],
      marks: map['marks'] ?? 1,
      imagePath: map['image_path'], // ✅ READ FROM DB
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
      'marks': marks,
      'image_path': imagePath, // ✅ SAVE TO DB
    };
  }
}
