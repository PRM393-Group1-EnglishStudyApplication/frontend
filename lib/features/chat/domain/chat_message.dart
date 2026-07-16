enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    required this.sentAt,
    this.isWelcome = false,
  });

  final ChatRole role;
  final String text;
  final DateTime sentAt;
  final bool isWelcome;

  Map<String, String> toHistoryJson() => <String, String>{
    'role': role.name,
    'text': text,
  };
}
