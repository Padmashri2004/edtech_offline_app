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

  // Convert Database Map to Exam Object
  factory ExamModel.fromMap(Map<String, dynamic> map) {
    return ExamModel(
      id: map['id'],
      title: map['title'],
      difficulty: map['difficulty'],
      timestamp: map['timestamp'],
      questions: (jsonDecode(map['questions_json']) as List)
          .map((q) => QuestionModel.fromMap(q))
          .toList(),
    );
  }

  // Convert Exam Object to Database Map for saving
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'difficulty': difficulty,
      'timestamp': timestamp,
      'questions_json': jsonEncode(questions.map((q) => q.toMap()).toList()),
    };
  }
}

class QuestionModel {
  final String question;
  final List<String> options;
  final int answerIndex;

  QuestionModel({
    required this.question,
    required this.options,
    required this.answerIndex,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      question: map['question'],
      options: List<String>.from(map['options']),
      answerIndex: map['answer_index'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'answer_index': answerIndex,
    };
  }
}