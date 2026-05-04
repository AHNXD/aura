import 'package:aura/models/chat_conversation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message.dart';

class ChatHistoryService {
  ChatHistoryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String defaultConversationTitle = 'New conversation';

  CollectionReference<Map<String, dynamic>> _conversationsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('conversations');
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(
    String userId,
    String conversationId,
  ) {
    return _conversationsRef(userId).doc(conversationId).collection('messages');
  }

  CollectionReference<Map<String, dynamic>> _legacyMessagesRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_messages');
  }

  Future<List<ChatConversation>> loadConversations(String userId) async {
    final snapshot = await _conversationsRef(userId)
        .orderBy('updatedAt', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ChatConversation(
        id: doc.id,
        title: data['title'] as String? ?? defaultConversationTitle,
        lastMessagePreview: data['lastMessagePreview'] as String? ?? '',
        createdAt: _parseTimestamp(data['createdAt']),
        updatedAt: _parseTimestamp(data['updatedAt']),
      );
    }).toList();
  }

  Future<List<Message>> loadMessages(
    String userId,
    String conversationId,
  ) async {
    final snapshot = await _messagesRef(
      userId,
      conversationId,
    ).orderBy('timestamp').get(const GetOptions(source: Source.serverAndCache));

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Message(
        text: data['text'] as String? ?? '',
        isUser: data['isUser'] as bool? ?? false,
        timestamp: _parseTimestamp(data['timestamp']),
      );
    }).toList();
  }

  Future<ChatConversation> createConversation(
    String userId, {
    required Message welcomeMessage,
  }) async {
    final now = welcomeMessage.timestamp;
    final doc = _conversationsRef(userId).doc();

    final conversation = ChatConversation(
      id: doc.id,
      title: defaultConversationTitle,
      lastMessagePreview: _previewFromText(welcomeMessage.text),
      createdAt: now,
      updatedAt: now,
    );

    final batch = _firestore.batch();
    batch.set(doc, {
      'title': conversation.title,
      'lastMessagePreview': conversation.lastMessagePreview,
      'createdAt': Timestamp.fromDate(conversation.createdAt),
      'updatedAt': Timestamp.fromDate(conversation.updatedAt),
    });
    batch.set(_messagesRef(userId, doc.id).doc(), {
      'text': welcomeMessage.text,
      'isUser': welcomeMessage.isUser,
      'timestamp': Timestamp.fromDate(welcomeMessage.timestamp),
    });
    await batch.commit();

    return conversation;
  }

  Future<ChatConversation> saveMessage({
    required String userId,
    required String conversationId,
    required Message message,
    String? conversationTitle,
  }) async {
    final conversationRef = _conversationsRef(userId).doc(conversationId);
    final messageRef = _messagesRef(userId, conversationId).doc();
    final normalizedTitle = _normalizeTitle(conversationTitle);
    final existingConversation = await conversationRef.get();
    final existingData = existingConversation.data() ?? <String, dynamic>{};
    final createdAt = _parseTimestamp(
      existingData['createdAt'],
      fallback: message.timestamp,
    );

    final batch = _firestore.batch();
    batch.set(messageRef, {
      'text': message.text,
      'isUser': message.isUser,
      'timestamp': Timestamp.fromDate(message.timestamp),
    });
    batch.set(conversationRef, {
      'title': normalizedTitle ?? defaultConversationTitle,
      'lastMessagePreview': _previewFromText(message.text),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(message.timestamp),
    }, SetOptions(merge: true));
    await batch.commit();

    return ChatConversation(
      id: conversationId,
      title:
          normalizedTitle ??
          existingData['title'] as String? ??
          defaultConversationTitle,
      lastMessagePreview: _previewFromText(message.text),
      createdAt: createdAt,
      updatedAt: message.timestamp,
    );
  }

  Future<void> deleteConversation(String userId, String conversationId) async {
    final messagesSnapshot = await _messagesRef(userId, conversationId).get();
    final batch = _firestore.batch();

    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_conversationsRef(userId).doc(conversationId));
    await batch.commit();
  }

  Future<void> migrateLegacyMessagesIfNeeded(String userId) async {
    final existingConversations = await _conversationsRef(
      userId,
    ).limit(1).get();
    if (existingConversations.docs.isNotEmpty) {
      return;
    }

    final legacySnapshot = await _legacyMessagesRef(
      userId,
    ).orderBy('timestamp').get(const GetOptions(source: Source.serverAndCache));
    if (legacySnapshot.docs.isEmpty) {
      return;
    }

    final firstMessageData = legacySnapshot.docs.first.data();
    final firstTimestamp = _parseTimestamp(firstMessageData['timestamp']);
    final conversationDoc = _conversationsRef(userId).doc();
    final batch = _firestore.batch();

    batch.set(conversationDoc, {
      'title': _buildTitleFromLegacyMessages(legacySnapshot.docs),
      'lastMessagePreview': _previewFromText(
        legacySnapshot.docs.last.data()['text'] as String? ?? '',
      ),
      'createdAt': Timestamp.fromDate(firstTimestamp),
      'updatedAt': Timestamp.fromDate(
        _parseTimestamp(legacySnapshot.docs.last.data()['timestamp']),
      ),
    });

    for (final legacyDoc in legacySnapshot.docs) {
      final data = legacyDoc.data();
      batch.set(_messagesRef(userId, conversationDoc.id).doc(), {
        'text': data['text'] as String? ?? '',
        'isUser': data['isUser'] as bool? ?? false,
        'timestamp': _coerceTimestamp(data['timestamp']),
      });
      batch.delete(legacyDoc.reference);
    }

    await batch.commit();
  }

  static String previewForMessage(String text) => _previewFromText(text);

  static String buildConversationTitleFromMessage(String text) {
    final cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) {
      return defaultConversationTitle;
    }

    return cleaned.length <= 36 ? cleaned : '${cleaned.substring(0, 33)}...';
  }

  static String? _normalizeTitle(String? title) {
    final trimmed = title?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static String _previewFromText(String text) {
    final cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) {
      return '';
    }

    return cleaned.length <= 72 ? cleaned : '${cleaned.substring(0, 69)}...';
  }

  String _buildTitleFromLegacyMessages(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    for (final doc in docs) {
      final data = doc.data();
      if (data['isUser'] == true) {
        return buildConversationTitleFromMessage(data['text'] as String? ?? '');
      }
    }
    return defaultConversationTitle;
  }

  DateTime _parseTimestamp(Object? value, {DateTime? fallback}) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
    }
    return fallback ?? DateTime.now();
  }

  Timestamp _coerceTimestamp(Object? value) {
    if (value is Timestamp) {
      return value;
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return Timestamp.fromDate(parsed);
      }
    }
    return Timestamp.fromDate(DateTime.now());
  }
}
