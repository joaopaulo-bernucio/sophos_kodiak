import '../services/api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isAnimating;
  final bool isError;
  final ApiException? apiError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isAnimating = false,
    this.isError = false,
    this.apiError,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isAnimating: json['isAnimating'] as bool? ?? false,
      isError: json['isError'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isAnimating': isAnimating,
      'isError': isError,
    };
  }

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isAnimating,
    bool? isError,
    ApiException? apiError,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isAnimating: isAnimating ?? this.isAnimating,
      isError: isError ?? this.isError,
      apiError: apiError ?? this.apiError,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(text: $text, isUser: $isUser, timestamp: $timestamp, isAnimating: $isAnimating, isError: $isError)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.text == text &&
        other.isUser == isUser &&
        other.timestamp == timestamp &&
        other.isAnimating == isAnimating &&
        other.isError == isError;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        isUser.hashCode ^
        timestamp.hashCode ^
        isAnimating.hashCode ^
        isError.hashCode;
  }
}
