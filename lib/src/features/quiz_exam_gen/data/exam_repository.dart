import 'package:edtech_offline_app/src/core/database/database_helper.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:logger/logger.dart';

class ExamRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Logger _logger = Logger();

  /// Save an exam to the DB
  Future<int> saveExam(ExamModel exam) async {
    try {
      exam.type = "exam"; // ✅ enforce type
      final db = await _dbHelper.database;
      return await db.transaction((txn) async {
        int examId = await txn.insert('exams', exam.toMap());
        exam.id = examId; // ✅ assign ID back to model
        for (var q in exam.questions) {
          await txn.insert('questions', q.toMap()..['exam_id'] = examId);
        }
        _logger
            .i("✅ Saved exam #$examId with ${exam.questions.length} questions");
        return examId;
      });
    } catch (e) {
      _logger.e("❌ Error saving exam: $e");
      return -1;
    }
  }

  /// Get a single exam by ID
  Future<ExamModel?> getExam(int id) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'exams',
        where: 'id = ? AND type = ?',
        whereArgs: [id, "exam"],
      );
      if (rows.isEmpty) return null;

      final exam = ExamModel.fromMap(rows.first);
      final questionRows = await db
          .query('questions', where: 'exam_id = ?', whereArgs: [exam.id]);
      exam.questions.addAll(
        questionRows.map((q) => QuestionModel.fromMap(q)).toList(),
      );
      return exam;
    } catch (e) {
      _logger.e("❌ Error loading exam: $e");
      return null;
    }
  }

  /// Get all exams
  Future<List<ExamModel>> getAllExams() async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'exams',
        where: 'type = ?',
        whereArgs: ["exam"],
        orderBy: 'timestamp DESC',
      );
      List<ExamModel> exams = [];
      for (var row in rows) {
        final exam = ExamModel.fromMap(row);
        final questionRows = await db
            .query('questions', where: 'exam_id = ?', whereArgs: [exam.id]);
        exam.questions.addAll(
          questionRows.map((q) => QuestionModel.fromMap(q)).toList(),
        );
        exams.add(exam);
      }
      return exams;
    } catch (e) {
      _logger.e("❌ Error loading exams: $e");
      return [];
    }
  }

  /// Delete an exam by ID
  Future<void> deleteExam(int id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete('questions', where: 'exam_id = ?', whereArgs: [id]);
      await db.delete(
        'exams',
        where: 'id = ? AND type = ?',
        whereArgs: [id, "exam"],
      );
      _logger.i("🗑️ Deleted exam $id");
    } catch (e) {
      _logger.e("❌ Error deleting exam: $e");
    }
  }
}
