import 'package:flutter/material.dart';
import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/ai_assistant/domain/chat_message.dart';

class AIChatController extends ChangeNotifier {
  final AIRepository _repository;
  
  // Member 1 Optimization: Making the reference final as the list is only mutated
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AIChatController(this._repository);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add User Message
    _messages.add(ChatMessage(text: text, role: MessageRole.user));
    _isLoading = true;
    notifyListeners();

    try {
      // 2. Request AI response through the Repository
      final response = await _repository.getMistakeExplanation(
        question: "General Query", 
        studentAns: text, 
        correctAns: "N/A"
      );

      // 3. Add AI Response
      _messages.add(ChatMessage(text: response, role: MessageRole.ai));
    } catch (e) {
      _messages.add(ChatMessage(
        text: "Error: Could not reach Gemma. Please check model initialization.", 
        role: MessageRole.ai
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Optional: Clear history for a fresh session
  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}
