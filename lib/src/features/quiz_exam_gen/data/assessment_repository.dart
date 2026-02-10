import 'package:logger/logger.dart';
import 'package:edtech_offline_app/src/core/database/database_helper.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

/// Unified repository for both Quiz (Module 1) and Exam (Module 6)
/// Eliminates code duplication while maintaining backward compatibility
class AssessmentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Logger _logger = Logger();

  // ============================================================================
  // GENERIC CRUD OPERATIONS (works for both quiz and exam)
  // ============================================================================

  /// Save assessment (quiz or exam) with all questions
  /// Returns the inserted assessment ID
  Future<int> saveAssessment(ExamModel assessment) async {
    try {
      final db = await _dbHelper.database;

      // Start transaction for atomic operation
      return await db.transaction((txn) async {
        // Insert assessment header
        final assessmentId = await txn.insert('exams', assessment.toMap());

        // Insert all questions
        for (var question in assessment.questions) {
          final questionMap = question.toMap();
          questionMap['exam_id'] = assessmentId;
          await txn.insert('questions', questionMap);
        }

        _logger.i("✅ ${assessment.type} saved with ID $assessmentId");
        return assessmentId;
      });
    } catch (e) {
      _logger.e("❌ Failed to save ${assessment.type}: $e");
      return -1;
    }
  }

  /// Get assessment by ID with all questions loaded
  Future<ExamModel?> getAssessment(int id) async {
    try {
      final db = await _dbHelper.database;

      // Get assessment header
      final assessmentMaps = await db.query(
        'exams',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (assessmentMaps.isEmpty) return null;

      final assessment = ExamModel.fromMap(assessmentMaps.first);

      // Get all questions for this assessment
      final questionMaps = await db.query(
        'questions',
        where: 'exam_id = ?',
        whereArgs: [id],
        orderBy: 'id ASC',
      );

      assessment.questions =
          questionMaps.map((map) => QuestionModel.fromMap(map)).toList();

      return assessment;
    } catch (e) {
      _logger.e("❌ Failed to get assessment: $e");
      return null;
    }
  }

  /// Get all assessments of a specific type (quiz or exam)
  Future<List<ExamModel>> getAssessmentsByType(String type) async {
    try {
      final db = await _dbHelper.database;

      // Get all assessments of specified type
      final assessmentMaps = await db.query(
        'exams',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'timestamp DESC',
      );

      List<ExamModel> assessments = [];

      for (var map in assessmentMaps) {
        final assessment = ExamModel.fromMap(map);

        // Load questions for each assessment
        final questionMaps = await db.query(
          'questions',
          where: 'exam_id = ?',
          whereArgs: [assessment.id],
          orderBy: 'id ASC',
        );

        assessment.questions =
            questionMaps.map((qMap) => QuestionModel.fromMap(qMap)).toList();

        assessments.add(assessment);
      }

      return assessments;
    } catch (e) {
      _logger.e("❌ Failed to get $type assessments: $e");
      return [];
    }
  }

  /// Get all assessments (both quiz and exam)
  Future<List<ExamModel>> getAllAssessments() async {
    try {
      final db = await _dbHelper.database;

      final assessmentMaps = await db.query(
        'exams',
        orderBy: 'timestamp DESC',
      );

      List<ExamModel> assessments = [];

      for (var map in assessmentMaps) {
        final assessment = ExamModel.fromMap(map);

        final questionMaps = await db.query(
          'questions',
          where: 'exam_id = ?',
          whereArgs: [assessment.id],
          orderBy: 'id ASC',
        );

        assessment.questions =
            questionMaps.map((qMap) => QuestionModel.fromMap(qMap)).toList();

        assessments.add(assessment);
      }

      return assessments;
    } catch (e) {
      _logger.e("❌ Failed to get all assessments: $e");
      return [];
    }
  }

  /// Update assessment header (title, difficulty, timer, etc.)
  Future<bool> updateAssessment(ExamModel assessment) async {
    try {
      final db = await _dbHelper.database;

      final rowsAffected = await db.update(
        'exams',
        assessment.toMap(),
        where: 'id = ?',
        whereArgs: [assessment.id],
      );

      _logger.i("✅ Updated ${assessment.type} ID ${assessment.id}");
      return rowsAffected > 0;
    } catch (e) {
      _logger.e("❌ Failed to update assessment: $e");
      return false;
    }
  }

  /// Update a single question
  Future<bool> updateQuestion(QuestionModel question) async {
    try {
      final db = await _dbHelper.database;

      final rowsAffected = await db.update(
        'questions',
        question.toMap(),
        where: 'id = ?',
        whereArgs: [question.id],
      );

      return rowsAffected > 0;
    } catch (e) {
      _logger.e("❌ Failed to update question: $e");
      return false;
    }
  }

  /// Delete assessment and all its questions (cascade delete)
  Future<bool> deleteAssessment(int id) async {
    try {
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        // Delete all questions first
        await txn.delete(
          'questions',
          where: 'exam_id = ?',
          whereArgs: [id],
        );

        // Delete assessment header
        await txn.delete(
          'exams',
          where: 'id = ?',
          whereArgs: [id],
        );
      });

      _logger.i("🗑️ Deleted assessment ID $id");
      return true;
    } catch (e) {
      _logger.e("❌ Failed to delete assessment: $e");
      return false;
    }
  }

  /// Delete a single question
  Future<bool> deleteQuestion(int questionId) async {
    try {
      final db = await _dbHelper.database;

      final rowsAffected = await db.delete(
        'questions',
        where: 'id = ?',
        whereArgs: [questionId],
      );

      return rowsAffected > 0;
    } catch (e) {
      _logger.e("❌ Failed to delete question: $e");
      return false;
    }
  }

  // ============================================================================
  // QUERY & FILTER OPERATIONS
  // ============================================================================

  /// Get assessments by difficulty level
  Future<List<ExamModel>> getAssessmentsByDifficulty(String difficulty) async {
    try {
      final db = await _dbHelper.database;

      final assessmentMaps = await db.query(
        'exams',
        where: 'difficulty = ?',
        whereArgs: [difficulty],
        orderBy: 'timestamp DESC',
      );

      List<ExamModel> assessments = [];

      for (var map in assessmentMaps) {
        final assessment = ExamModel.fromMap(map);

        final questionMaps = await db.query(
          'questions',
          where: 'exam_id = ?',
          whereArgs: [assessment.id],
          orderBy: 'id ASC',
        );

        assessment.questions =
            questionMaps.map((qMap) => QuestionModel.fromMap(qMap)).toList();

        assessments.add(assessment);
      }

      return assessments;
    } catch (e) {
      _logger.e("❌ Failed to get assessments by difficulty: $e");
      return [];
    }
  }

  /// Search assessments by title
  Future<List<ExamModel>> searchAssessments(String query) async {
    try {
      final db = await _dbHelper.database;

      final assessmentMaps = await db.query(
        'exams',
        where: 'title LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'timestamp DESC',
      );

      List<ExamModel> assessments = [];

      for (var map in assessmentMaps) {
        final assessment = ExamModel.fromMap(map);

        final questionMaps = await db.query(
          'questions',
          where: 'exam_id = ?',
          whereArgs: [assessment.id],
          orderBy: 'id ASC',
        );

        assessment.questions =
            questionMaps.map((qMap) => QuestionModel.fromMap(qMap)).toList();

        assessments.add(assessment);
      }

      return assessments;
    } catch (e) {
      _logger.e("❌ Failed to search assessments: $e");
      return [];
    }
  }

  // ============================================================================
  // STATISTICS & ANALYTICS
  // ============================================================================

  /// Get count of assessments by type
  Future<int> getAssessmentCount({String? type}) async {
    try {
      final db = await _dbHelper.database;

      if (type != null) {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM exams WHERE type = ?',
          [type],
        );
        return result.first['count'] as int;
      } else {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM exams');
        return result.first['count'] as int;
      }
    } catch (e) {
      _logger.e("❌ Failed to get assessment count: $e");
      return 0;
    }
  }

  /// Get total number of questions
  Future<int> getTotalQuestionCount() async {
    try {
      final db = await _dbHelper.database;
      final result =
          await db.rawQuery('SELECT COUNT(*) as count FROM questions');
      return result.first['count'] as int;
    } catch (e) {
      _logger.e("❌ Failed to get question count: $e");
      return 0;
    }
  }

  /// Get statistics for a specific type
  Future<Map<String, dynamic>> getStatistics(String type) async {
    try {
      final assessments = await getAssessmentsByType(type);

      int totalQuestions = 0;
      int totalMarks = 0;

      for (var assessment in assessments) {
        totalQuestions += assessment.questions.length;
        totalMarks += assessment.totalMarks;
      }

      return {
        'count': assessments.length,
        'totalQuestions': totalQuestions,
        'totalMarks': totalMarks,
        'averageQuestions': assessments.isEmpty
            ? 0
            : (totalQuestions / assessments.length).round(),
        'averageMarks':
            assessments.isEmpty ? 0 : (totalMarks / assessments.length).round(),
      };
    } catch (e) {
      _logger.e("❌ Failed to get statistics: $e");
      return {};
    }
  }

  // ============================================================================
  // BACKWARD COMPATIBILITY HELPERS
  // ============================================================================

  /// Save quiz (calls saveAssessment with type='quiz')
  Future<int> saveQuiz(ExamModel quiz) async {
    quiz.type = 'quiz';
    return await saveAssessment(quiz);
  }

  /// Save exam (calls saveAssessment with type='exam')
  Future<int> saveExam(ExamModel exam) async {
    exam.type = 'exam';
    return await saveAssessment(exam);
  }

  /// Get quiz by ID
  Future<ExamModel?> getQuiz(int id) async {
    final assessment = await getAssessment(id);
    return (assessment?.type == 'quiz') ? assessment : null;
  }

  /// Get exam by ID
  Future<ExamModel?> getExam(int id) async {
    final assessment = await getAssessment(id);
    return (assessment?.type == 'exam') ? assessment : null;
  }

  /// Get all quizzes
  Future<List<ExamModel>> getAllQuizzes() async {
    return await getAssessmentsByType('quiz');
  }

  /// Get all exams
  Future<List<ExamModel>> getAllExams() async {
    return await getAssessmentsByType('exam');
  }

  /// Delete quiz
  Future<bool> deleteQuiz(int id) async {
    return await deleteAssessment(id);
  }

  /// Delete exam
  Future<bool> deleteExam(int id) async {
    return await deleteAssessment(id);
  }
}
