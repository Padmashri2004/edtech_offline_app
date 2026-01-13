import 'package:flutter/material.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:logger/logger.dart';

class ExamProvider with ChangeNotifier {
  final QuizRepository _repository = QuizRepository();
  final Logger _logger = Logger();

  List<ExamModel> _exams = [];
  bool _isLoading = false;

  List<ExamModel> get exams => _exams;
  bool get isLoading => _isLoading;

  /// Fetches all saved exams from the offline database
  Future<void> loadExams() async {
    _isLoading = true;
    notifyListeners();

    try {
      _exams = await _repository.getAllExams();
      _logger.i("📊 Member 1: Loaded ${_exams.length} exams from DB.");
    } catch (e) {
      _logger.e("❌ Member 1: Error loading exams: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves a newly generated exam and refreshes the list
  Future<void> saveExam(ExamModel exam) async {
    final result = await _repository.saveExam(exam);
    if (result != -1) {
      _logger.i("💾 Member 1: Exam saved successfully.");
      await loadExams(); // Refresh list
    }
  }

  /// Deletes an exam from the local store
  Future<void> deleteExam(int id) async {
    await _repository.deleteExam(id);
    _exams.removeWhere((exam) => exam.id == id);
    notifyListeners();
    _logger.i("🗑️ Member 1: Exam $id removed.");
  }
}