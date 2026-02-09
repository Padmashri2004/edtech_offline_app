import 'dart:convert';

class ExamModel {
  int? id;
  String title;
  String difficulty;
  String timestamp;
  int timerMinutes; // ✅ teacher must provide this
  int totalMarks; // ✅ teacher must provide this
  String type; // "quiz" or "exam"
  List<QuestionModel> questions;

  ExamModel({
    this.id,
    required this.title,
    required this.difficulty,
    required this.timestamp,
    required this.timerMinutes,
    required this.totalMarks,
    required this.type,
    required this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'difficulty': difficulty,
      'timestamp': timestamp,
      'timer_minutes': timerMinutes,
      'total_marks': totalMarks,
      'type': type,
    };
  }

  factory ExamModel.fromMap(Map<String, dynamic> map) {
    return ExamModel(
      id: map['id'] as int?,
      title: map['title'] ?? '',
      difficulty: map['difficulty'] ?? '',
      timestamp: map['timestamp'] ?? '',
      timerMinutes: map['timer_minutes'] is int
          ? map['timer_minutes']
          : int.tryParse(map['timer_minutes'].toString()) ?? 0, // ✅ no default
      totalMarks: map['total_marks'] is int
          ? map['total_marks']
          : int.tryParse(map['total_marks'].toString()) ?? 0, // ✅ no default
      type: map['type'] ?? 'quiz',
      questions: [],
    );
  }
}

class QuestionModel {
  int? id;
  int? examId;
  String type; // MCQ, True/False, etc.
  String questionText;
  List<String> options;
  String correctAnswer;
  String? explanation;
  int marks; // ✅ teacher must provide
  String? imagePath;

  QuestionModel({
    this.id,
    this.examId,
    required this.type,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    required this.marks,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam_id': examId,
      'type': type,
      'question_text': questionText,
      'options': jsonEncode(options),
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'marks': marks,
      'image_path': imagePath,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] as int?,
      examId: map['exam_id'] as int?,
      type: map['type'] ?? 'MCQ',
      questionText: map['question_text'] ?? '',
      options: (map['options'] != null)
          ? List<String>.from(jsonDecode(map['options']))
          : [],
      correctAnswer: map['correct_answer'] ?? '',
      explanation: map['explanation'],
      marks: map['marks'] is int
          ? map['marks']
          : int.tryParse(map['marks'].toString()) ?? 0, // ✅ no default
      imagePath: map['image_path'],
    );
  }
}
