class ExamModel {
  final int? id;
  final String title;
  final String type; // 'quiz' or 'exam'
  final String difficulty;
  final int timerMinutes;
  final int totalMarks;
  final List<QuestionModel> questions;
  final String timestamp;
  final bool published;
  final Map<String, String>? metadata; // ✅ NEW: class, subject, textbook

  ExamModel({
    this.id,
    required this.title,
    required this.type,
    required this.difficulty,
    required this.timerMinutes,
    required this.totalMarks,
    required this.questions,
    required this.timestamp,
    this.published = false,
    this.metadata, // ✅ NEW
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'difficulty': difficulty,
      'timer_minutes': timerMinutes,
      'total_marks': totalMarks,
      'timestamp': timestamp,
      'published': published ? 1 : 0,
      'class_name': metadata?['class'], // ✅ NEW
      'subject': metadata?['subject'], // ✅ NEW
      'textbook_name': metadata?['textbookName'], // ✅ NEW
    };
  }

  // Create from Map (database)
  factory ExamModel.fromMap(Map<String, dynamic> map) {
    return ExamModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      type: map['type'] as String,
      difficulty: map['difficulty'] as String,
      timerMinutes: map['timer_minutes'] as int,
      totalMarks: map['total_marks'] as int,
      questions: [],
      timestamp: map['timestamp'] as String,
      published: (map['published'] as int?) == 1,
      metadata: {
        // ✅ NEW
        if (map['class_name'] != null) 'class': map['class_name'] as String,
        if (map['subject'] != null) 'subject': map['subject'] as String,
        if (map['textbook_name'] != null)
          'textbookName': map['textbook_name'] as String,
      },
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'difficulty': difficulty,
      'timerMinutes': timerMinutes,
      'totalMarks': totalMarks,
      'questions': questions.map((q) => q.toJson()).toList(),
      'timestamp': timestamp,
      'published': published,
      'metadata': metadata, // ✅ NEW
    };
  }

  // Create from JSON
  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      type: json['type'] as String,
      difficulty: json['difficulty'] as String,
      timerMinutes: json['timerMinutes'] as int,
      totalMarks: json['totalMarks'] as int,
      questions: (json['questions'] as List)
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      timestamp: json['timestamp'] as String,
      published: json['published'] as bool? ?? false,
      metadata: json['metadata'] != null // ✅ NEW
          ? Map<String, String>.from(json['metadata'] as Map)
          : null,
    );
  }

  // Copy with method
  ExamModel copyWith({
    int? id,
    String? title,
    String? type,
    String? difficulty,
    int? timerMinutes,
    int? totalMarks,
    List<QuestionModel>? questions,
    String? timestamp,
    bool? published,
    Map<String, String>? metadata, // ✅ NEW
  }) {
    return ExamModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      totalMarks: totalMarks ?? this.totalMarks,
      questions: questions ?? this.questions,
      timestamp: timestamp ?? this.timestamp,
      published: published ?? this.published,
      metadata: metadata ?? this.metadata, // ✅ NEW
    );
  }
}

class QuestionModel {
  final int? id;
  final String questionText;
  final String type;
  final List<String> options;
  final String correctAnswer;
  final int marks;
  final String explanation;
  final String? imagePath; // ✅ For exam papers only (auto-extracted from PDF)

  QuestionModel({
    this.id,
    required this.questionText,
    required this.type,
    this.options = const [],
    required this.correctAnswer,
    required this.marks,
    this.explanation = '',
    this.imagePath, // ✅ Set during PDF scan for exam papers
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_text': questionText,
      'type': type,
      'options': options.join('|||'),
      'correct_answer': correctAnswer,
      'marks': marks,
      'explanation': explanation,
      'image_path': imagePath,
    };
  }

  // Create from Map (database)
  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    final optionsString = map['options'] as String? ?? '';
    final options =
        optionsString.isEmpty ? <String>[] : optionsString.split('|||');

    return QuestionModel(
      id: map['id'] as int?,
      questionText: map['question_text'] as String,
      type: map['type'] as String,
      options: options,
      correctAnswer: map['correct_answer'] as String,
      marks: map['marks'] as int,
      explanation: map['explanation'] as String? ?? '',
      imagePath: map['image_path'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
      'marks': marks,
      'explanation': explanation,
      'imagePath': imagePath,
    };
  }

  // Create from JSON
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as int?,
      questionText: json['questionText'] as String,
      type: json['type'] as String,
      options: (json['options'] as List?)?.cast<String>() ?? [],
      correctAnswer: json['correctAnswer'] as String,
      marks: json['marks'] as int,
      explanation: json['explanation'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
    );
  }

  // Copy with method
  QuestionModel copyWith({
    int? id,
    String? questionText,
    String? type,
    List<String>? options,
    String? correctAnswer,
    int? marks,
    String? explanation,
    String? imagePath,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      marks: marks ?? this.marks,
      explanation: explanation ?? this.explanation,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
