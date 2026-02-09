import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/exam_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/paper_generation_service.dart';
import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/session_manager.dart';

class ExamProvider extends ChangeNotifier {
  final ExamRepository _examRepository = ExamRepository();
  final PaperGenerationService _paperService =
      PaperGenerationService(AIRepository());
  final SessionManager _sessionManager = SessionManager();
  final Logger _logger = Logger();

  ExamModel? _currentExam;
  bool _loading = false;
  String? _error;
  double extractionProgress = 0.0;
  double quizProgress = 0.0;
  double paperProgress = 0.0;
  String? currentChapterTitle;

  ExamModel? get currentExam => _currentExam;
  bool get isLoading => _loading;
  String? get error => _error;

  /// Load an existing exam by ID (with restoration if available)
  Future<void> loadExam(int examId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final exam = await _examRepository.getExam(examId);
      if (exam != null) {
        exam.type = "exam"; // ✅ enforce type
        // Try restoring session state
        final session = await _sessionManager.restoreSessionState();
        if (session != null &&
            session['examId'] == examId &&
            session['examType'] == "exam") {
          _logger.i("🔄 Restored exam session for ID $examId");
          // You can use session['timeLeft'], session['currentIndex'], session['answers']
        }
      }
      _currentExam = exam;
    } catch (e) {
      _logger.e("❌ Failed to load exam: $e");
      _error = "Failed to load exam";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// FIXED: Generate exam with tier (Basic/Advanced) - 100 marks automatic
  Future<void> generateExamWithTier({
    required String title,
    required String difficulty, // "Basic" or "Advanced"
    required List<String> topics,
    required String rawContent, // Chapter text
  }) async {
    _loading = true;
    _error = null;
    extractionProgress = 0.0;
    quizProgress = 0.0;
    paperProgress = 0.0;
    currentChapterTitle = null;
    notifyListeners();

    try {
      final exam = await _paperService.generateExamPaper(
        title: title,
        difficulty: difficulty,
        topics: topics,
        rawContent: rawContent,
        onProgress: (double progress) {
          quizProgress = progress;
          notifyListeners();
        },
      );

      if (exam == null) {
        _error = "No exam generated";
      } else {
        exam.type = "exam"; // ✅ mark as exam
        _currentExam = exam;
        // Save session state
        await _sessionManager.saveSessionState(
          exam: _currentExam!,
          timeLeft: 120, // 2 hours
          currentIndex: 0,
          answers: {},
        );
      }
    } catch (e) {
      _logger.e("❌ Exam generation failed: $e");
      _error = "Exam generation failed: $e";
    } finally {
      _loading = false;
      currentChapterTitle = null;
      notifyListeners();
    }
  }

  /// Generate a new exam paper using PaperGenerationService (OLD METHOD - kept for compatibility)
  Future<void> generateExam({
    required String title,
    required String difficulty,
    required List<String> topics,
    required int timerMinutes,
    required int totalMarks,
    required List<Map<String, dynamic>> types,
  }) async {
    _loading = true;
    _error = null;
    extractionProgress = 0.0;
    quizProgress = 0.0;
    paperProgress = 0.0;
    currentChapterTitle = null;
    notifyListeners();
    try {
      final exam = await _paperService.generateExamPaper(
        title: title,
        difficulty: difficulty,
        topics: topics,
        rawContent: '', // Empty for old method
        onProgress: (double progress) {
          quizProgress = progress;
          notifyListeners();
        },
      );
      if (exam == null) {
        _error = "No exam generated";
      } else {
        exam.type = "exam"; // ✅ mark as exam
        _currentExam = exam;
        // Save session state
        await _sessionManager.saveSessionState(
          exam: _currentExam!,
          timeLeft: timerMinutes,
          currentIndex: 0,
          answers: {},
        );
      }
    } catch (e) {
      _logger.e("❌ Exam generation failed: $e");
      _error = "Exam generation failed";
    } finally {
      _loading = false;
      currentChapterTitle = null;
      notifyListeners();
    }
  }

  /// Save the current exam to DB and persist session
  Future<void> saveExam(
    ExamModel exam, {
    int timeLeft = 0,
    int currentIndex = 0,
    Map<int, String> answers = const {},
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      exam.type = "exam"; // ✅ enforce type before saving
      final examId = await _examRepository.saveExam(exam);
      if (examId == -1) {
        _error = "Failed to save exam";
      } else {
        _logger.i("✅ Exam saved with ID $examId");
        _currentExam = exam..id = examId;
        // Save session state
        await _sessionManager.saveSessionState(
          exam: _currentExam!,
          timeLeft: timeLeft,
          currentIndex: currentIndex,
          answers: answers,
        );
      }
    } catch (e) {
      _logger.e("❌ Failed to save exam: $e");
      _error = "Failed to save exam";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Delete an exam by ID and clear session
  Future<void> deleteExam(int examId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _examRepository.deleteExam(examId);
      _logger.i("🗑️ Exam $examId deleted");
      if (_currentExam?.id == examId) {
        _currentExam = null;
      }
      await _sessionManager.clearSessionState();
    } catch (e) {
      _logger.e("❌ Failed to delete exam: $e");
      _error = "Failed to delete exam";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Clear current exam state
  void clearExam() {
    _currentExam = null;
    _error = null;
    extractionProgress = 0.0;
    quizProgress = 0.0;
    paperProgress = 0.0;
    currentChapterTitle = null;
    _sessionManager.clearSessionState();
    notifyListeners();
  }
}
