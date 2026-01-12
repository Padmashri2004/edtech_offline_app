import 'package:edtech_offline_app/src/core/database/database_helper.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:logger/logger.dart';

class QuizRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Logger _logger = Logger();

  /// Saves a new AI-generated exam to the local database
  Future<int> saveExam(ExamModel exam) async {
    try {
      final db = await _dbHelper.database;
      _logger.i("💾 Member 1: Saving exam '${exam.title}' to database...");
      return await db.insert('exams', exam.toMap());
    } catch (e) {
      _logger.e("❌ Member 1: Error saving exam: $e");
      return -1;
    }
  }

  /// Retrieves all exams stored offline
  Future<List<ExamModel>> getAllExams() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('exams', orderBy: 'timestamp DESC');
      
      return List.generate(maps.length, (i) => ExamModel.fromMap(maps[i]));
    } catch (e) {
      _logger.e("❌ Member 1: Error fetching exams: $e");
      return [];
    }
  }

  /// Deletes an exam (e.g., if a teacher wants to recreate it)
  Future<void> deleteExam(int id) async {
    final db = await _dbHelper.database;
    await db.delete('exams', where: 'id = ?', whereArgs: [id]);
    _logger.i("🗑️ Member 1: Exam $id deleted.");
  }
}