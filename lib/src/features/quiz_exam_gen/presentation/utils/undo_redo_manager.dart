/// A simple Undo/Redo manager to track changes in exam editing.
/// Stores a stack of states and allows stepping backward/forward.
class UndoRedoManager<T> {
  final List<T> _undoStack = [];
  final List<T> _redoStack = [];

  /// Current state
  T? _current;

  /// Returns the current state
  T? get current => _current;

  /// Apply a new state and clear redo history
  void apply(T newState) {
    if (_current != null) {
      _undoStack.add(_current as T);
    }
    _current = newState;
    _redoStack.clear();
  }

  /// Undo the last change
  T? undo() {
    if (_undoStack.isEmpty) return _current;
    _redoStack.add(_current as T);
    _current = _undoStack.removeLast();
    return _current;
  }

  /// Redo the last undone change
  T? redo() {
    if (_redoStack.isEmpty) return _current;
    _undoStack.add(_current as T);
    _current = _redoStack.removeLast();
    return _current;
  }

  /// Clear all history
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _current = null;
  }

  /// Check if undo is possible
  bool get canUndo => _undoStack.isNotEmpty;

  /// Check if redo is possible
  bool get canRedo => _redoStack.isNotEmpty;
}
