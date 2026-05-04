class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.title,
    required this.lastMessagePreview,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String lastMessagePreview;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation copyWith({
    String? id,
    String? title,
    String? lastMessagePreview,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
