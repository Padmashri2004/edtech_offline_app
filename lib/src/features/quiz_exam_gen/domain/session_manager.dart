import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

class SessionManager {
  /// Save current session state (quiz or exam)
  Future<void> saveSessionState({
    required ExamModel exam,
    required int timeLeft,
    required int currentIndex,
    required Map<int, String> answers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_exam_id', exam.id ?? -1);
    await prefs.setString('active_exam_type', exam.type);
    await prefs.setInt('time_left', timeLeft);
    await prefs.setInt('current_index', currentIndex);

    // ✅ CRITICAL FIX: Encode Map as JSON String
    await prefs.setString(
        'answers_json',
        jsonEncode(
            answers.map((key, value) => MapEntry(key.toString(), value))));
  }

  /// Restore session state if available
  Future<Map<String, dynamic>?> restoreSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    final examId = prefs.getInt('active_exam_id');
    final examType = prefs.getString('active_exam_type');

    if (examId == null || examId == -1 || examType == null) return null;

    // ✅ CRITICAL FIX: Parse JSON back to Map
    final String? answersJson = prefs.getString('answers_json');
    Map<int, String> restoredAnswers = {};
    if (answersJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(answersJson);
      decoded.forEach((key, value) {
        restoredAnswers[int.parse(key)] = value.toString();
      });
    }

    return {
      'examId': examId,
      'examType': examType,
      'timeLeft': prefs.getInt('time_left') ?? 0,
      'currentIndex': prefs.getInt('current_index') ?? 0,
      'answers': restoredAnswers,
    };
  }

  Future<void> clearSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_exam_id');
    await prefs.remove('active_exam_type');
    await prefs.remove('time_left');
    await prefs.remove('current_index');
    await prefs.remove('answers_json');
  }
}
