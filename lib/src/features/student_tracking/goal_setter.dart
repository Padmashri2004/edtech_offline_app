import '../../core/database/database_helper.dart';
//import 'package:sqflite/sqflite.dart';

class GoalSetterService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createGoal({
    required String studentId,
    required String goalTitle,
    required String targetDate,
  }) async {
    final db = await _dbHelper.database;
    // Inserts a new study goal into the database
    await db.insert('study_goals', {
      'student_id': studentId,
      'goal_title': goalTitle,
      'target_date': targetDate,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> completeGoal(int goalId) async {
    final db = await _dbHelper.database;
    // Marks a specific goal as completed
    await db.update(
      'study_goals',
      {'status': 'completed'},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }
}