import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

/// Enhanced Undo/Redo manager for exam editing with deep copy support
class UndoRedoManager {
  final List<List<QuestionModel>> _undoStack = [];
  final List<List<QuestionModel>> _redoStack = [];
  final int maxStackSize;

  UndoRedoManager({this.maxStackSize = 50});

  /// Save current state to undo stack
  void saveState(List<QuestionModel> questions) {
    // Deep copy the questions list
    final stateCopy = _deepCopyQuestions(questions);
    _undoStack.add(stateCopy);

    // Clear redo stack when new state is saved
    _redoStack.clear();

    // Maintain max stack size
    if (_undoStack.length > maxStackSize) {
      _undoStack.removeAt(0);
    }
  }

  /// Undo last change and return previous state
  List<QuestionModel>? undo(List<QuestionModel> currentState) {
    if (_undoStack.isEmpty) return null;

    // Save current state to redo stack
    _redoStack.add(_deepCopyQuestions(currentState));

    // Get previous state from undo stack
    final previousState = _undoStack.removeLast();

    // Maintain max redo stack size
    if (_redoStack.length > maxStackSize) {
      _redoStack.removeAt(0);
    }

    return previousState;
  }

  /// Redo last undone change and return next state
  List<QuestionModel>? redo(List<QuestionModel> currentState) {
    if (_redoStack.isEmpty) return null;

    // Save current state to undo stack
    _undoStack.add(_deepCopyQuestions(currentState));

    // Get next state from redo stack
    final nextState = _redoStack.removeLast();

    // Maintain max undo stack size
    if (_undoStack.length > maxStackSize) {
      _undoStack.removeAt(0);
    }

    return nextState;
  }

  /// Deep copy questions list to avoid reference issues
  List<QuestionModel> _deepCopyQuestions(List<QuestionModel> questions) {
    return questions.map((q) => _copyQuestion(q)).toList();
  }

  /// Create a deep copy of a single question
  QuestionModel _copyQuestion(QuestionModel question) {
    return QuestionModel(
      id: question.id,
      type: question.type,
      questionText: question.questionText,
      options: List<String>.from(question.options), // Deep copy list
      correctAnswer: question.correctAnswer,
      explanation: question.explanation,
      marks: question.marks,
      imagePath: question.imagePath,
    );
  }

  /// Check if undo is available
  bool get canUndo => _undoStack.isNotEmpty;

  /// Check if redo is available
  bool get canRedo => _redoStack.isNotEmpty;

  /// Get number of undo states available
  int get undoCount => _undoStack.length;

  /// Get number of redo states available
  int get redoCount => _redoStack.length;

  /// Clear all undo/redo history
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  /// Peek at the most recent undo state without removing it
  List<QuestionModel>? peekUndo() {
    if (_undoStack.isEmpty) return null;
    return _deepCopyQuestions(_undoStack.last);
  }

  /// Peek at the most recent redo state without removing it
  List<QuestionModel>? peekRedo() {
    if (_redoStack.isEmpty) return null;
    return _deepCopyQuestions(_redoStack.last);
  }

  /// Get current stack sizes (for debugging/UI display)
  Map<String, int> get stackInfo => {
        'undoCount': _undoStack.length,
        'redoCount': _redoStack.length,
        'maxSize': maxStackSize,
      };
}
