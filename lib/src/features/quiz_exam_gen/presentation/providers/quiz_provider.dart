import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/session_manager.dart';

class QuizProvider extends ChangeNotifier {
  final QuizRepository _quizRepository = QuizRepository();
  final SessionManager _sessionManager = SessionManager();
  final Logger _logger = Logger();

  ExamModel? _currentQuiz;
  bool _loading = false;
  String? _error;

  ExamModel? get currentQuiz => _currentQuiz;
  bool get isLoading => _loading;
  String? get error => _error;

  /// Load an existing quiz by ID (with restoration if available)
  Future<void> loadQuiz(int quizId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final quiz = await _quizRepository.getQuiz(quizId);
      if (quiz != null) {
        quiz.type = "quiz"; // ✅ enforce type

        // Try restoring session state
        final session = await _sessionManager.restoreSessionState();
        if (session != null &&
            session['examId'] == quizId &&
            session['examType'] == "quiz") {
          _logger.i("🔄 Restored quiz session for ID $quizId");
          // You can use session['timeLeft'], session['currentIndex'], session['answers']
        }
      }
      _currentQuiz = quiz;
    } catch (e) {
      _logger.e("❌ Failed to load quiz: $e");
      _error = "Failed to load quiz";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Save a new quiz to DB and persist session
  Future<void> saveQuiz(ExamModel quiz,
      {int timeLeft = 0,
      int currentIndex = 0,
      Map<int, String> answers = const {}}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      quiz.type = "quiz"; // ✅ enforce type before saving
      final quizId = await _quizRepository.saveQuiz(quiz);
      if (quizId == -1) {
        _error = "Failed to save quiz";
      } else {
        _logger.i("✅ Quiz saved with ID $quizId");
        _currentQuiz = quiz..id = quizId;

        // Save session state
        await _sessionManager.saveSessionState(
          exam: _currentQuiz!,
          timeLeft: timeLeft,
          currentIndex: currentIndex,
          answers: answers,
        );
      }
    } catch (e) {
      _logger.e("❌ Failed to save quiz: $e");
      _error = "Failed to save quiz";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Delete a quiz by ID and clear session
  Future<void> deleteQuiz(int quizId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _quizRepository.deleteQuiz(quizId);
      _logger.i("🗑️ Quiz $quizId deleted");
      if (_currentQuiz?.id == quizId) {
        _currentQuiz = null;
      }
      await _sessionManager.clearSessionState();
    } catch (e) {
      _logger.e("❌ Failed to delete quiz: $e");
      _error = "Failed to delete quiz";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Clear current quiz state
  void clearQuiz() {
    _currentQuiz = null;
    _error = null;
    _sessionManager.clearSessionState();
    notifyListeners();
  }
}
