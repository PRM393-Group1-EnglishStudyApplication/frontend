enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String text;
  final DateTime sentAt;
  final bool isWelcome;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.sentAt,
    this.isWelcome = false,
  });
}
