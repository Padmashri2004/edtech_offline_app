import '../../core/database/database_helper.dart';

/// Manages study goals for students
/// Uses `study_goals` table
class GoalSetterService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Create a new study goal
  Future<void> createGoal({
    required String studentId,
    required String goalTitle,
    required String targetDate,
  }) async {
    final _ = await _dbHelper.database;

    // TODO: Insert into study_goals table
  }

  /// Mark a goal as completed
  Future<void> completeGoal(int goalId) async {
    // TODO: Update status to 'completed'
  }
}
