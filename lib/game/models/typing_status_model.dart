// Typing status model
class TypingStatus {
  final String userId;
  final String userName;
  final bool isTyping;
  final DateTime timestamp;

  TypingStatus({
    required this.userId,
    required this.userName,
    required this.isTyping,
    required this.timestamp,
  });
}
