import '../../core/database/database_helper.dart';

/// Handles student–alumni mentorship connections
/// Uses `mentorship_requests` table
class ConnectionService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Send a mentorship request
  Future<void> requestMentorship({
    required String studentId,
    required String alumniId,
  }) async {
    final _ = await _dbHelper.database;

    // TODO: Insert new request with status = 'requested'
  }

  /// Update mentorship request status
  Future<void> updateRequestStatus({
    required int requestId,
    required String status,
  }) async {
    // TODO: Update request status (accepted/rejected)
  }
}
