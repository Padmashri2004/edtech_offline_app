import 'package:flutter/foundation.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/assessment_repository.dart';
import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/domain/paper_generation_service.dart';
import 'package:edtech_offline_app/services/image_extraction_service.dart';

class AssessmentProvider extends ChangeNotifier {
  final AssessmentRepository _repository = AssessmentRepository();
  final AIRepository _aiRepository = AIRepository();
  final ImageExtractionService _imageService = ImageExtractionService();
  late final PaperGenerationService _paperGenService;

  AssessmentProvider() {
    _paperGenService = PaperGenerationService(_aiRepository);
  }

  // State
  ExamModel? _currentAssessment;
  List<ExamModel> _quizzes = [];
  List<ExamModel> _exams = [];
  bool _isLoading = false;
  String? _error;

  // Progress tracking
  double _generationProgress = 0.0;
  String _currentStatus = '';
  int _questionsGenerated = 0;
  int _totalQuestions = 0;

  // Getters
  ExamModel? get currentAssessment => _currentAssessment;
  List<ExamModel> get quizzes => _quizzes;
  List<ExamModel> get exams => _exams;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get generationProgress => _generationProgress;
  String get currentStatus => _currentStatus;
  int get questionsGenerated => _questionsGenerated;
  int get totalQuestions => _totalQuestions;

  // ✅ NEW: Set current assessment
  void setCurrentAssessment(ExamModel assessment) {
    _currentAssessment = assessment;
    notifyListeners();
  }

  // Update progress
  void _updateProgress(int generated, int total, String status) {
    _questionsGenerated = generated;
    _totalQuestions = total;
    _generationProgress = total > 0 ? generated / total : 0.0;
    _currentStatus = status;
    notifyListeners();
  }

  // Generate quiz with progress
  Future<void> generateQuiz({
    required String title,
    required String difficulty,
    required List<String> topics,
    required int timerMinutes,
    required int totalMarks,
    required List<Map<String, dynamic>> types,
    Map<String, String>? metadata, // ✅ NEW
  }) async {
    _isLoading = true;
    _error = null;
    _generationProgress = 0.0;
    _questionsGenerated = 0;
    notifyListeners();

    try {
      final List<QuestionModel> allQuestions = [];

      final total = types.fold<int>(
        0,
        (sum, type) => sum + (type['count'] as int),
      );
      _totalQuestions = total;

      int generated = 0;

      for (final typeInfo in types) {
        final type = typeInfo['type'] as String;
        final count = typeInfo['count'] as int;
        final marksPerQ = typeInfo['marks'] as int;

        _updateProgress(generated, total, 'Generating $type questions...');

        for (int i = 0; i < count; i++) {
          try {
            final question = await _aiRepository.generateQuestion(
              type: type,
              difficulty: difficulty,
              topic: topics.isNotEmpty ? topics.first : 'general',
              marks: marksPerQ,
            );

            if (question != null) {
              allQuestions.add(question);
              generated++;
              _updateProgress(
                  generated, total, 'Generated $generated/$total questions');
            }
          } catch (e) {
            debugPrint('Error generating question: $e');
          }

          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      _currentAssessment = ExamModel(
        title: title,
        type: 'quiz',
        difficulty: difficulty,
        timerMinutes: timerMinutes,
        totalMarks: totalMarks,
        questions: allQuestions,
        timestamp: DateTime.now().toIso8601String(),
        published: false,
        metadata: metadata, // ✅ NEW
      );

      _updateProgress(total, total, 'Quiz generated successfully!');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _generationProgress = 0.0;
      notifyListeners();
    }
  }

  // Generate exam with tier, progress, and images
  Future<void> generateExamWithTier({
    required String title,
    required String difficulty,
    required List<String> topics,
    required String rawContent,
    Map<String, String>? metadata, // ✅ NEW
    List<Map<String, dynamic>>? extractedImages, // ✅ NEW
  }) async {
    _isLoading = true;
    _error = null;
    _generationProgress = 0.0;
    _questionsGenerated = 0;
    notifyListeners();

    try {
      _updateProgress(0, 100, 'Preparing exam structure...');

      final exam = await _paperGenService.generatePaper(
        title: title,
        tier: difficulty,
        topics: topics,
        content: rawContent,
        onProgress: (generated, total, status) {
          _updateProgress(generated, total, status);
        },
      );

      // ✅ NEW: Match images to questions
      if (extractedImages != null && extractedImages.isNotEmpty) {
        for (var question in exam.questions) {
          final matchedImage = _imageService.findRelevantImage(
            question.questionText,
            extractedImages,
          );

          if (matchedImage != null) {
            // Update question with image
            final index = exam.questions.indexOf(question);
            exam.questions[index] = question.copyWith(imagePath: matchedImage);
          }
        }
      }

      // ✅ Add metadata
      _currentAssessment = exam.copyWith(metadata: metadata);

      _updateProgress(100, 100, 'Exam paper generated successfully!');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _generationProgress = 0.0;
      notifyListeners();
    }
  }

  // Save assessment
  Future<void> saveAssessment(ExamModel assessment) async {
    try {
      await _repository.saveAssessment(assessment);
      if (assessment.type == 'quiz') {
        await loadQuizzes();
      } else {
        await loadExams();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load quizzes
  Future<void> loadQuizzes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _quizzes = await _repository.getAssessmentsByType('quiz');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load exams
  Future<void> loadExams() async {
    _isLoading = true;
    notifyListeners();

    try {
      _exams = await _repository.getAssessmentsByType('exam');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ NEW: Load all assessments (for history)
  Future<void> loadAllAssessments() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadQuizzes();
      await loadExams();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete assessment
  Future<void> deleteAssessment(int id) async {
    try {
      await _repository.deleteAssessment(id);
      await loadAllAssessments();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Reset progress
  void resetProgress() {
    _generationProgress = 0.0;
    _currentStatus = '';
    _questionsGenerated = 0;
    _totalQuestions = 0;
    notifyListeners();
  }
}
