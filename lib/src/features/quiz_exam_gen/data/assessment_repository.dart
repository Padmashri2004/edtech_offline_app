import 'package:edtech_offline_app/src/core/database/database_helper.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:logger/logger.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

class AssessmentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Logger _logger = Logger();

  // Save assessment (quiz or exam)
  Future<int> saveAssessment(ExamModel exam) async {
    try {
      final db = await _dbHelper.database;

      int examId;
      if (exam.id != null) {
        // Update existing
        await db.update(
          'exams',
          exam.toMap(),
          where: 'id = ?',
          whereArgs: [exam.id],
        );
        examId = exam.id!;

        // Delete old questions
        await db.delete('questions', where: 'exam_id = ?', whereArgs: [examId]);
      } else {
        // Insert new
        examId = await db.insert('exams', exam.toMap());
      }

      // Save questions
      for (var question in exam.questions) {
        final questionMap = question.toMap();
        questionMap['exam_id'] = examId;
        await db.insert('questions', questionMap);
      }

      _logger.i('✅ Assessment saved: $examId');
      return examId;
    } catch (e) {
      _logger.e('Error saving assessment: $e');
      rethrow;
    }
  }

  // Get assessment by ID
  Future<ExamModel> getAssessmentById(int id) async {
    try {
      final db = await _dbHelper.database;

      final maps = await db.query('exams', where: 'id = ?', whereArgs: [id]);
      if (maps.isEmpty) throw Exception('Assessment not found');

      var exam = ExamModel.fromMap(maps.first);

      final questionMaps = await db.query(
        'questions',
        where: 'exam_id = ?',
        whereArgs: [id],
      );

      final questions =
          questionMaps.map((m) => QuestionModel.fromMap(m)).toList();

      // ✅ FIXED: Use copyWith instead of direct assignment
      return exam.copyWith(questions: questions);
    } catch (e) {
      _logger.e('Error getting assessment: $e');
      rethrow;
    }
  }

  // Get assessments by type (quiz or exam)
  Future<List<ExamModel>> getAssessmentsByType(String type) async {
    try {
      final db = await _dbHelper.database;

      final maps = await db.query(
        'exams',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'timestamp DESC',
      );

      final List<ExamModel> assessments = [];

      for (var map in maps) {
        var exam = ExamModel.fromMap(map);

        final questionMaps = await db.query(
          'questions',
          where: 'exam_id = ?',
          whereArgs: [exam.id],
        );

        final questions =
            questionMaps.map((m) => QuestionModel.fromMap(m)).toList();

        // ✅ FIXED: Use copyWith
        assessments.add(exam.copyWith(questions: questions));
      }

      return assessments;
    } catch (e) {
      _logger.e('Error getting assessments by type: $e');
      return [];
    }
  }

  // Get published assessments only
  Future<List<ExamModel>> getPublishedAssessments(String type) async {
    try {
      final db = await _dbHelper.database;

      final maps = await db.query(
        'exams',
        where: 'type = ? AND published = 1',
        whereArgs: [type],
        orderBy: 'timestamp DESC',
      );

      final List<ExamModel> assessments = [];

      for (var map in maps) {
        var exam = ExamModel.fromMap(map);

        final questionMaps = await db.query(
          'questions',
          where: 'exam_id = ?',
          whereArgs: [exam.id],
        );

        final questions =
            questionMaps.map((m) => QuestionModel.fromMap(m)).toList();

        // ✅ FIXED: Use copyWith
        assessments.add(exam.copyWith(questions: questions));
      }

      return assessments;
    } catch (e) {
      _logger.e('Error getting published assessments: $e');
      return [];
    }
  }

  // Delete assessment
  Future<void> deleteAssessment(int id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete('exams', where: 'id = ?', whereArgs: [id]);
      // Questions are deleted automatically due to CASCADE
      _logger.i('✅ Assessment deleted: $id');
    } catch (e) {
      _logger.e('Error deleting assessment: $e');
      rethrow;
    }
  }

  // Check if question already exists (deduplication)
  Future<bool> questionExists(QuestionModel question) async {
    try {
      final db = await _dbHelper.database;

      // Create hash of question
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

  // Save question to history (for deduplication)
  Future<void> saveQuestionHistory(QuestionModel question) async {
    try {
      final db = await _dbHelper.database;

      final hash = _generateQuestionHash(question);

      await db.insert(
        'question_history',
        {
          'question_hash': hash,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      _logger.e('Error saving question history: $e');
    }
  }

  // Generate hash for question deduplication
  String _generateQuestionHash(QuestionModel question) {
    final content =
        '${question.questionText}${question.type}${question.correctAnswer}';
    final bytes = utf8.encode(content);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}
