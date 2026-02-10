import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/assessment_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/paper_generation_service.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/quiz_generation_service.dart';
import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/session_manager.dart';

/// Unified provider for both Quiz (Module 1) and Exam (Module 6)
/// Replaces separate QuizProvider and ExamProvider
class AssessmentProvider extends ChangeNotifier {
  final AssessmentRepository _repository = AssessmentRepository();
  final PaperGenerationService _paperService =
      PaperGenerationService(AIRepository());
  final QuizGenerationService _quizService =
      QuizGenerationService(AIRepository());
  final SessionManager _sessionManager = SessionManager();
  final Logger _logger = Logger();

  // State
  ExamModel? _currentAssessment;
  List<ExamModel> _quizzes = [];
  List<ExamModel> _exams = [];
  bool _loading = false;
  String? _error;

  // Progress tracking
  double extractionProgress = 0.0;
  double generationProgress = 0.0;
  String? currentChapterTitle;

  // Getters
  ExamModel? get currentAssessment => _currentAssessment;
  List<ExamModel> get quizzes => _quizzes;
  List<ExamModel> get exams => _exams;
  bool get isLoading => _loading;
  String? get error => _error;

  // ============================================================================
  // LOAD OPERATIONS
  // ============================================================================

  /// Load all quizzes
  Future<void> loadQuizzes() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _quizzes = await _repository.getAllQuizzes();
      _logger.i("✅ Loaded ${_quizzes.length} quizzes");
    } catch (e) {
      _logger.e("❌ Failed to load quizzes: $e");
      _error = "Failed to load quizzes";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Load all exams
  Future<void> loadExams() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _exams = await _repository.getAllExams();
      _logger.i("✅ Loaded ${_exams.length} exams");
    } catch (e) {
      _logger.e("❌ Failed to load exams: $e");
      _error = "Failed to load exams";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Load both quizzes and exams
  Future<void> loadAllAssessments() async {
    await loadQuizzes();
    await loadExams();
  }

  /// Load specific assessment by ID
  Future<void> loadAssessment(int id, String type) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final assessment = await _repository.getAssessment(id);

      if (assessment != null && assessment.type == type) {
        _currentAssessment = assessment;

        // Try restoring session state
        final session = await _sessionManager.restoreSessionState();
        if (session != null && session['examId'] == id) {
          _logger.i("🔄 Restored session for $type ID $id");
        }
      } else {
        _error = "Assessment not found or type mismatch";
      }
    } catch (e) {
      _logger.e("❌ Failed to load assessment: $e");
      _error = "Failed to load assessment";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // GENERATION OPERATIONS
  // ============================================================================

  /// Generate quiz (Module 1)
  Future<void> generateQuiz({
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
    generationProgress = 0.0;
    notifyListeners();

    try {
      final quiz = await _quizService.generateQuiz(
        title: title,
        difficulty: difficulty,
        topics: topics,
        timerMinutes: timerMinutes,
        totalMarks: totalMarks,
        types: types,
        onProgress: (progress) {
          generationProgress = progress;
          notifyListeners();
        },
      );

      if (quiz == null) {
        _error = "No quiz generated";
      } else {
        quiz.type = "quiz";
        _currentAssessment = quiz;
        await loadQuizzes(); // Refresh list

        _logger.i("✅ Quiz generated successfully");
      }
    } catch (e) {
      _logger.e("❌ Quiz generation failed: $e");
      _error = "Quiz generation failed: $e";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Generate exam with tier (Module 6)
  Future<void> generateExamWithTier({
    required String title,
    required String difficulty,
    required List<String> topics,
    required String rawContent,
  }) async {
    _loading = true;
    _error = null;
    extractionProgress = 0.0;
    generationProgress = 0.0;
    notifyListeners();

    try {
      final exam = await _paperService.generateExamPaper(
        title: title,
        difficulty: difficulty,
        topics: topics,
        rawContent: rawContent,
        onProgress: (progress) {
          generationProgress = progress;
          notifyListeners();
        },
      );

      if (exam == null) {
        _error = "No exam generated";
      } else {
        exam.type = "exam";
        _currentAssessment = exam;
        await loadExams(); // Refresh list

        // Save session state
        await _sessionManager.saveSessionState(
          exam: exam,
          timeLeft: 120,
          currentIndex: 0,
          answers: {},
        );

        _logger.i("✅ Exam generated successfully");
      }
    } catch (e) {
      _logger.e("❌ Exam generation failed: $e");
      _error = "Exam generation failed: $e";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // SAVE/UPDATE/DELETE OPERATIONS
  // ============================================================================

  /// Save assessment (quiz or exam)
  Future<void> saveAssessment(
    ExamModel assessment, {
    int timeLeft = 0,
    int currentIndex = 0,
    Map<int, String> answers = const {},
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final assessmentId = await _repository.saveAssessment(assessment);

      if (assessmentId == -1) {
        _error = "Failed to save ${assessment.type}";
      } else {
        _logger.i("✅ ${assessment.type} saved with ID $assessmentId");
        _currentAssessment = assessment..id = assessmentId;

        // Refresh appropriate list
        if (assessment.type == 'quiz') {
          await loadQuizzes();
        } else {
          await loadExams();
        }

        // Save session state
        await _sessionManager.saveSessionState(
          exam: _currentAssessment!,
          timeLeft: timeLeft,
          currentIndex: currentIndex,
          answers: answers,
        );
      }
    } catch (e) {
      _logger.e("❌ Failed to save ${assessment.type}: $e");
      _error = "Failed to save ${assessment.type}";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Update assessment
  Future<void> updateAssessment(ExamModel assessment) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.updateAssessment(assessment);

      if (success) {
        _currentAssessment = assessment;

        // Refresh appropriate list
        if (assessment.type == 'quiz') {
          await loadQuizzes();
        } else {
          await loadExams();
        }

        _logger.i("✅ ${assessment.type} updated");
      } else {
        _error = "Failed to update ${assessment.type}";
      }
    } catch (e) {
      _logger.e("❌ Failed to update: $e");
      _error = "Failed to update ${assessment.type}";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Delete assessment
  Future<void> deleteAssessment(int id, String type) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.deleteAssessment(id);

      if (success) {
        _logger.i("🗑️ $type $id deleted");

        if (_currentAssessment?.id == id) {
          _currentAssessment = null;
          await _sessionManager.clearSessionState();
        }

        // Refresh appropriate list
        if (type == 'quiz') {
          await loadQuizzes();
        } else {
          await loadExams();
        }
      } else {
        _error = "Failed to delete $type";
      }
    } catch (e) {
      _logger.e("❌ Failed to delete: $e");
      _error = "Failed to delete $type";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // UTILITY OPERATIONS
  // ============================================================================

  /// Clear current assessment
  void clearAssessment() {
    _currentAssessment = null;
    _error = null;
    extractionProgress = 0.0;
    generationProgress = 0.0;
    currentChapterTitle = null;
    _sessionManager.clearSessionState();
    notifyListeners();
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics(String type) async {
    return await _repository.getStatistics(type);
  }

  /// Search assessments
  Future<List<ExamModel>> searchAssessments(String query) async {
    return await _repository.searchAssessments(query);
  }

  /// Get assessments by difficulty
  Future<List<ExamModel>> getByDifficulty(String difficulty) async {
    return await _repository.getAssessmentsByDifficulty(difficulty);
  }
}
