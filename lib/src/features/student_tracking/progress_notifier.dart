import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';

class ProgressNotifier extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _studentProgress = [];
  List<Map<String, dynamic>> get studentProgress => _studentProgress;

  Future<void> loadStudentProgress(String studentId) async {
    final db = await _dbHelper.database;
    // Fetches progress records for a specific student
    _studentProgress = await db.query(
      'student_progress',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    notifyListeners();
  }

  Future<void> updateProgress({
    required String studentId,
    required String subject,
    required String chapter,
    required int progressPercent,
  }) async {
    final db = await _dbHelper.database;
    // Updates the progress percent and sets the last updated timestamp
    await db.insert(
      'student_progress',
      {
        'student_id': studentId,
        'subject': subject,
        'chapter': chapter,
        'progress_percent': progressPercent,
        'last_updated': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await loadStudentProgress(studentId);
  }
}