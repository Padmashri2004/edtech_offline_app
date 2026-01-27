import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

/// Manages undo/redo operations for question editing
class UndoRedoManager {
  final List<List<QuestionModel>> _undoStack = [];
  final List<List<QuestionModel>> _redoStack = [];
  final int maxStackSize;

  UndoRedoManager({this.maxStackSize = 50});

  void saveState(List<QuestionModel> questions) {
    final snapshot = questions.map((q) => _copyQuestion(q)).toList();
    _undoStack.add(snapshot);
    _redoStack.clear();

    if (_undoStack.length > maxStackSize) {
      _undoStack.removeAt(0);
    }
  }

  List<QuestionModel>? undo(List<QuestionModel> currentQuestions) {
    if (!canUndo) return null;

    final currentSnapshot =
        currentQuestions.map((q) => _copyQuestion(q)).toList();
    _redoStack.add(currentSnapshot);

    return _undoStack.removeLast();
  }

  List<QuestionModel>? redo(List<QuestionModel> currentQuestions) {
    if (!canRedo) return null;

    final currentSnapshot =
        currentQuestions.map((q) => _copyQuestion(q)).toList();
    _undoStack.add(currentSnapshot);

    return _redoStack.removeLast();
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  QuestionModel _copyQuestion(QuestionModel q) {
    return QuestionModel(
      id: q.id,
      examId: q.examId,
      questionText: q.questionText,
      options: q.options is List ? List.from(q.options as List) : q.options,
      correctAnswer: q.correctAnswer,
      explanation: q.explanation,
      marks: q.marks,
      imagePath: q.imagePath,
    );
  }
}
