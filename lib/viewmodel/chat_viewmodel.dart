import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  
  final List<Message> _messages = [];
  bool _isLoading = false;

  // Getters
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  /// Initialize chat with a welcome message
  void initializeChat() {
    if (_messages.isEmpty) {
      addMessage(
        Message(
          text: 'Hello! I\'m your medical assistant. How can I help you today?\nNote: I am a medical assistant, but this does not replace consulting a doctor.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Add a message to the chat
  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  /// Remove the last message (used for removing loading indicators)
  void removeLastMessage() {
    if (_messages.isNotEmpty) {
      _messages.removeLast();
      notifyListeners();
    }
  }

  /// Send a message to the n8n webhook
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    try {
      // Add user message to chat
      final userMessage = Message(
        text: text.trim(),
        isUser: true,
        timestamp: DateTime.now(),
      );
      addMessage(userMessage);

      // Add loading indicator
      _isLoading = true;
      final loadingMessage = Message(
        text: 'typing',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      );
      addMessage(loadingMessage);

      // Send message to n8n
      final response = await _chatService.sendMessageToN8n(text.trim());

      // Remove loading indicator
      removeLastMessage();

      // Add assistant response
      final assistantMessage = Message(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      addMessage(assistantMessage);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Remove loading indicator
      removeLastMessage();

      // Add error message
      final errorMessage = Message(
        text: 'Sorry, I encountered an error. Please try again. Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
      );
      addMessage(errorMessage);

      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear chat history
  void clearChat() {
    _messages.clear();
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
