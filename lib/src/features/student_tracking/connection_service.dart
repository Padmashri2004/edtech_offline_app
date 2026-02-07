import '../../core/database/database_helper.dart';

class ConnectionService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> requestMentorship({
    required String studentId,
    required String alumniId,
  }) async {
    final db = await _dbHelper.database;
    // Records a new mentorship request
    await db.insert('mentorship_requests', {
      'student_id': studentId,
      'alumni_id': alumniId,
      'status': 'requested',
      'requested_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateRequestStatus({
    required int requestId,
    required String status,
  }) async {
    final db = await _dbHelper.database;
    // Allows alumni or admins to accept/reject requests
    await db.update(
      'mentorship_requests',
      {'status': status},
      where: 'id = ?',
      whereArgs: [requestId],
    );
  }
}