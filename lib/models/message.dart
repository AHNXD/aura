class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });

  // Copy with method for immutability
  Message copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return Message(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      text: map['text'] as String? ?? '',
      isUser: map['isUser'] as bool? ?? false,
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  String toString() =>
      'Message(text: $text, isUser: $isUser, timestamp: $timestamp, isLoading: $isLoading)';
}
