import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';
import 'package:edtech_offline_app/src/core/database/database_helper.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

class AssessmentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Logger _logger = Logger();

  // ==========================================
  // 1. DEDUPLICATION LOGIC (SHA-256)
  // ==========================================

  String _generateQuestionHash(QuestionModel question) {
    // Hash based on text and type to ensure mathematical consistency
    final content =
        '${question.questionText.toLowerCase().trim()}${question.type}';
    final bytes = utf8.encode(content);
    return sha256.convert(bytes).toString();
  }

  Future<bool> questionExists(QuestionModel question) async {
    try {
      final db = await _dbHelper.database;
      final hash = _generateQuestionHash(question);
      final result = await db.query(
        'question_history',
        where: 'question_hash = ?',
        whereArgs: [hash],
      );
      return result.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking question existence: $e');
      return false;
    }
  }

  Future<void> saveQuestionHistory(QuestionModel question) async {
    try {
      final db = await _dbHelper.database;
      final hash = _generateQuestionHash(question);
      await db.insert(
        'question_history',
        {
          'question_hash': hash,
          'created_at': DateTime.now().toIso8601String(),
          'topic': '',
          'chapter_title': '',
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      _logger.e('Error saving history: $e');
    }
  }

  // ==========================================
  // 2. CRUD OPERATIONS (Fixed Provider Errors)
  // ==========================================

  /// Saves or Updates an entire Assessment (Quiz or Exam)
  Future<int> saveAssessment(ExamModel exam) async {
    try {
      final db = await _dbHelper.database;
      int examId;

      if (exam.id != null) {
        // Update existing header
        await db.update(
          'exams',
          exam.toMap(),
          where: 'id = ?',
          whereArgs: [exam.id],
        );
        examId = exam.id!;
        // Clear old questions for this ID to prevent duplicates on update
        await db.delete('questions', where: 'exam_id = ?', whereArgs: [examId]);
      } else {
        // Insert new header
        examId = await db.insert('exams', exam.toMap());
      }

      // Save all questions associated with this exam
      for (var question in exam.questions) {
        final questionMap = question.toMap();
        questionMap['exam_id'] = examId; // Attach Foreign Key
        await db.insert('questions', questionMap);

        // Simultaneously track in history for AI deduplication
        await saveQuestionHistory(question);
      }

      _logger.i('✅ Assessment $examId saved successfully.');
      return examId;
    } catch (e) {
      _logger.e('Error saving assessment: $e');
      rethrow;
    }
  }

  /// Fetches a list of assessments by type ('quiz' or 'exam')
  Future<List<ExamModel>> getAssessmentsByType(String type) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'exams',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'timestamp DESC',
      );

      List<ExamModel> assessments = [];
      for (var map in maps) {
        final examId = map['id'];

        // Fetch questions for this specific exam
        final List<Map<String, dynamic>> questionMaps = await db.query(
          'questions',
          where: 'exam_id = ?',
          whereArgs: [examId],
        );

        final questions =
            questionMaps.map((m) => QuestionModel.fromMap(m)).toList();

        assessments.add(ExamModel.fromMap(map).copyWith(questions: questions));
      }
      return assessments;
    } catch (e) {
      _logger.e('Error fetching assessments: $e');
      return [];
    }
  }

  /// Deletes an assessment and its questions (Cascade)
  Future<void> deleteAssessment(int id) async {
    try {
      final db = await _dbHelper.database;
      // Because of ON DELETE CASCADE in your DatabaseHelper,
      // deleting the exam will automatically delete the associated questions.
      await db.delete('exams', where: 'id = ?', whereArgs: [id]);
      _logger.i('🗑️ Assessment $id deleted.');
    } catch (e) {
      _logger.e('Error deleting assessment: $e');
      rethrow;
    }
  }

  /// Fetches a single assessment by ID
  Future<ExamModel> getAssessmentById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('exams', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) throw Exception('Assessment not found');

    final List<Map<String, dynamic>> qMaps =
        await db.query('questions', where: 'exam_id = ?', whereArgs: [id]);
    final questions = qMaps.map((m) => QuestionModel.fromMap(m)).toList();

    return ExamModel.fromMap(maps.first).copyWith(questions: questions);
  }
}
