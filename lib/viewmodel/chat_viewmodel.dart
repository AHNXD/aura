import 'package:aura/models/chat_conversation.dart';
import 'package:aura/models/message.dart';
import 'package:aura/services/auth_service.dart';
import 'package:aura/services/chat_history_service.dart';
import 'package:aura/services/chat_service.dart';
import 'package:flutter/material.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel(
    this._authService, {
    ChatService? chatService,
    ChatHistoryService? chatHistoryService,
  }) : _chatService = chatService ?? ChatService(),
       _chatHistoryService = chatHistoryService ?? ChatHistoryService();

  final AuthService _authService;
  final ChatService _chatService;
  final ChatHistoryService _chatHistoryService;

  final List<Message> _messages = [];
  final List<ChatConversation> _conversations = [];

  bool _isLoading = false;
  bool _isInitializing = false;
  String? _historyError;
  String? _activeConversationId;

  List<Message> get messages => List.unmodifiable(_messages);
  List<ChatConversation> get conversations => List.unmodifiable(_conversations);
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get historyError => _historyError;
  String? get activeConversationId => _activeConversationId;

  ChatConversation? get activeConversation {
    for (final conversation in _conversations) {
      if (conversation.id == _activeConversationId) {
        return conversation;
      }
    }
    return null;
  }

  String? get _currentUserId => _authService.currentUser?.uid;

  Future<void> initializeChat() async {
    if (_isInitializing) {
      return;
    }

    _isInitializing = true;
    _historyError = null;
    notifyListeners();

    try {
      final userId = _currentUserId;
      if (userId == null) {
        _messages
          ..clear()
          ..add(_buildWelcomeMessage());
        return;
      }

      await _chatHistoryService.migrateLegacyMessagesIfNeeded(userId);
      await _loadConversationsAndActivate(userId);
    } catch (_) {
      _historyError =
          'We could not restore your previous chats yet. You can still start a new one.';
      _conversations.clear();
      _messages
        ..clear()
        ..add(_buildWelcomeMessage());
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> createNewConversation() async {
    final userId = _currentUserId;
    if (userId == null || _isLoading || _isInitializing) {
      return;
    }

    _isInitializing = true;
    _historyError = null;
    notifyListeners();

    try {
      final welcomeMessage = _buildWelcomeMessage();
      final conversation = await _chatHistoryService.createConversation(
        userId,
        welcomeMessage: welcomeMessage,
      );

      _messages
        ..clear()
        ..add(welcomeMessage);
      _activeConversationId = conversation.id;
      _upsertConversation(conversation, makeActive: true);
    } catch (_) {
      _historyError =
          'We could not create a new conversation right now. Please try again.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> selectConversation(String conversationId) async {
    final userId = _currentUserId;
    if (userId == null ||
        _isInitializing ||
        _activeConversationId == conversationId) {
      return;
    }

    _isInitializing = true;
    _historyError = null;
    notifyListeners();

    try {
      final loadedMessages = await _chatHistoryService.loadMessages(
        userId,
        conversationId,
      );
      _messages
        ..clear()
        ..addAll(loadedMessages);
      _activeConversationId = conversationId;
    } catch (_) {
      _historyError =
          'We could not open that conversation yet. Please try again.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    final userId = _currentUserId;
    if (userId == null || _isInitializing || _isLoading) {
      return;
    }

    _isInitializing = true;
    _historyError = null;
    notifyListeners();

    try {
      final wasActiveConversation = conversationId == _activeConversationId;
      await _chatHistoryService.deleteConversation(userId, conversationId);
      _conversations.removeWhere(
        (conversation) => conversation.id == conversationId,
      );

      if (_conversations.isEmpty) {
        final welcomeMessage = _buildWelcomeMessage();
        final newConversation = await _chatHistoryService.createConversation(
          userId,
          welcomeMessage: welcomeMessage,
        );
        _conversations.add(newConversation);
        _activeConversationId = newConversation.id;
        _messages
          ..clear()
          ..add(welcomeMessage);
      } else if (wasActiveConversation) {
        final nextConversation = _conversations.first;
        _activeConversationId = nextConversation.id;
        final loadedMessages = await _chatHistoryService.loadMessages(
          userId,
          nextConversation.id,
        );
        _messages
          ..clear()
          ..addAll(loadedMessages);
      }
    } catch (_) {
      _historyError =
          'We could not delete that conversation right now. Please try again.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _isLoading || _isInitializing) {
      return;
    }

    final userId = _currentUserId;
    final conversation = activeConversation;
    if (userId == null || conversation == null) {
      return;
    }

    final userMessage = Message(
      text: trimmedText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    try {
      _historyError = null;
      _messages.add(userMessage);
      _isLoading = true;
      _messages.add(
        Message(
          text: 'typing',
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: true,
        ),
      );
      notifyListeners();

      final nextTitle =
          conversation.title == ChatHistoryService.defaultConversationTitle
          ? ChatHistoryService.buildConversationTitleFromMessage(trimmedText)
          : conversation.title;

      final savedUserConversation = await _chatHistoryService.saveMessage(
        userId: userId,
        conversationId: conversation.id,
        message: userMessage,
        conversationTitle: nextTitle,
      );
      _upsertConversation(savedUserConversation, makeActive: true);

      final response = await _chatService.sendMessageToN8n(
        trimmedText,
        sessionId: '${userId}_${conversation.id}',
      );

      _removeLoadingIndicator();

      final assistantMessage = Message(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(assistantMessage);

      final savedAssistantConversation = await _chatHistoryService.saveMessage(
        userId: userId,
        conversationId: conversation.id,
        message: assistantMessage,
        conversationTitle: savedUserConversation.title,
      );
      _upsertConversation(savedAssistantConversation, makeActive: true);
    } catch (e) {
      _removeLoadingIndicator();
      _messages.add(
        Message(
          text:
              'Sorry, I encountered an error. Please try again. Error: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearChat() async {
    final conversationId = _activeConversationId;
    if (conversationId == null) {
      return;
    }

    await deleteConversation(conversationId);
  }

  Future<void> _loadConversationsAndActivate(String userId) async {
    final loadedConversations = await _chatHistoryService.loadConversations(
      userId,
    );

    if (loadedConversations.isEmpty) {
      final welcomeMessage = _buildWelcomeMessage();
      final conversation = await _chatHistoryService.createConversation(
        userId,
        welcomeMessage: welcomeMessage,
      );
      _conversations
        ..clear()
        ..add(conversation);
      _activeConversationId = conversation.id;
      _messages
        ..clear()
        ..add(welcomeMessage);
      return;
    }

    _conversations
      ..clear()
      ..addAll(loadedConversations);

    final selectedConversationId =
        _conversations.any(
          (conversation) => conversation.id == _activeConversationId,
        )
        ? _activeConversationId!
        : _conversations.first.id;
    _activeConversationId = selectedConversationId;

    final loadedMessages = await _chatHistoryService.loadMessages(
      userId,
      selectedConversationId,
    );
    _messages
      ..clear()
      ..addAll(loadedMessages);
  }

  void _upsertConversation(
    ChatConversation conversation, {
    bool makeActive = false,
  }) {
    _conversations.removeWhere((item) => item.id == conversation.id);
    _conversations.insert(0, conversation);

    if (makeActive) {
      _activeConversationId = conversation.id;
    }
  }

  Message _buildWelcomeMessage() {
    return Message(
      text:
          'Hello! I\'m your medical assistant. How can I help you today?\nNote: I am a medical assistant, but this does not replace consulting a doctor.',
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  void _removeLoadingIndicator() {
    if (_messages.isNotEmpty && _messages.last.isLoading) {
      _messages.removeLast();
    }
  }
}
