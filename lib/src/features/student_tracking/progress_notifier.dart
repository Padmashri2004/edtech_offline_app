import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';

/// Handles student progress tracking logic
/// Uses `student_progress` table
class ProgressNotifier extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  

  /// Fetch progress data for a student (logic placeholder)
  Future<void> loadStudentProgress(String studentId) async {
    final _ = await _dbHelper.database;

       // final db = await _dbHelper.database;
    // TODO: Query student_progress table
    // Example use-case:
    // SELECT * FROM student_progress WHERE student_id = ?
  }

  /// Update progress percentage for a chapter
  Future<void> updateProgress({
    required String studentId,
    required String subject,
    required String chapter,
    required int progressPercent,
  }) async {
    // TODO: Update progress_percent and last_updated
  }
}
