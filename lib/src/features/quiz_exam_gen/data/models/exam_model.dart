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

  // Calculate total marks by summing question marks
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
      } catch (e) {
        // ignore malformed JSON
      }
    }

    return ExamModel(
      id: map['id'],
      title: map['title'],
      difficulty: map['difficulty'],
      timestamp: map['timestamp'],
      timerMinutes: map['timer_minutes'] ?? 30,
      assignedStudents: students,
      questions: [], // questions loaded separately
    );
  }
}

class QuestionModel {
  final int? id;
  final int? examId;
  final String questionText;
  final dynamic options; // can be List<String> or JSON string
  final String correctAnswer;
  final String? explanation;
  final int marks;
  final String? imagePath; // ✅ supports image attachment

  QuestionModel({
    this.id,
    this.examId,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.marks = 1,
    this.imagePath,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'],
      examId: map['exam_id'],
      questionText:
          map['question'] ?? map['question_text'] ?? 'No Question Text',
      options: map['options'],
      correctAnswer:
          map['answer_index']?.toString() ?? map['correct_answer'] ?? '',
      explanation: map['explanation'],
      marks: map['marks'] ?? 1, // ✅ default to 1 if missing
      imagePath: map['image_path'], // ✅ read from DB
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam_id': examId,
      'question_text': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'marks': marks,
      'image_path': imagePath,
    };
  }
}
