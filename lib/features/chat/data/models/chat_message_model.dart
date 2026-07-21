import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.role,
    required super.text,
    required super.sentAt,
    super.isWelcome,
  });

  factory ChatMessageModel.fromEntity(ChatMessage message) {
    return ChatMessageModel(
      role: message.role,
      text: message.text,
      sentAt: message.sentAt,
      isWelcome: message.isWelcome,
    );
  }

  /// Backend `/api/chat` expects each history turn as `{role, text}`.
  Map<String, dynamic> toHistoryJson() {
    return <String, dynamic>{
      'role': role.name,
      'text': text,
    };
  }
}
