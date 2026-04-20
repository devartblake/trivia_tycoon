import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/bootstrap/app_init.dart';
import '../../../core/networking/ws_protocol.dart';
import '../../utils/input_validator.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Service for managing typing indicators in chat conversations
class TypingIndicatorService extends ChangeNotifier {
  static final TypingIndicatorService _instance =
      TypingIndicatorService._internal();
  factory TypingIndicatorService() => _instance;
  TypingIndicatorService._internal();

  // Map of conversationId -> Set of userIds who are typing
  final Map<String, Set<String>> _typingUsers = {};

  // Map of conversationId -> Set of userNames for display
  final Map<String, Set<String>> _typingUserNames = {};

  // Timers for auto-clearing typing status
  final Map<String, Timer> _typingTimers = {};

  // Current user's typing status per conversation
  final Map<String, bool> _currentUserTyping = {};

  /// Get users currently typing in a conversation
  Set<String> getTypingUsers(String conversationId) {
    final safeId = InputValidator.safeString(conversationId);
    return Set.from(_typingUsers[safeId] ?? {});
  }

  /// Get formatted typing indicator text for display
  String getTypingText(String conversationId) {
    final safeId = InputValidator.safeString(conversationId);
    final typingNames = _typingUserNames[safeId] ?? {};

    if (typingNames.isEmpty) return '';

    if (typingNames.length == 1) {
      return '${typingNames.first} is typing...';
    } else if (typingNames.length == 2) {
      return '${typingNames.first} and ${typingNames.last} are typing...';
    } else if (typingNames.length == 3) {
      final namesList = typingNames.toList();
      return '${namesList[0]}, ${namesList[1]} and ${namesList[2]} are typing...';
    } else {
      return 'Several people are typing...';
    }
  }

  /// Check if anyone is typing in a conversation
  bool isAnyoneTyping(String conversationId) {
    final safeId = InputValidator.safeString(conversationId);
    return (_typingUsers[safeId]?.isNotEmpty ?? false);
  }

  /// Check if current user is typing in a conversation
  bool isCurrentUserTyping(String conversationId) {
    final safeId = InputValidator.safeString(conversationId);
    return _currentUserTyping[safeId] ?? false;
  }

  /// Start typing indicator for current user
  Future<void> startTyping(String conversationId) async {
    final safeId = InputValidator.safeString(conversationId);
    if (safeId.isEmpty) return;

    _currentUserTyping[safeId] = true;

    // Cancel existing timer for this conversation
    _typingTimers[safeId]?.cancel();

    // Set auto-stop timer (typing indicator expires after 3 seconds)
    _typingTimers[safeId] = Timer(const Duration(seconds: 3), () {
      stopTyping(safeId);
    });

    // Broadcast typing status to other users
    await _broadcastTypingStatus(safeId, true);

    notifyListeners();
  }

  /// Stop typing indicator for current user
  Future<void> stopTyping(String conversationId) async {
    final safeId = InputValidator.safeString(conversationId);
    if (safeId.isEmpty) return;

    _currentUserTyping[safeId] = false;
    _typingTimers[safeId]?.cancel();
    _typingTimers.remove(safeId);

    // Broadcast stop typing status
    await _broadcastTypingStatus(safeId, false);

    notifyListeners();
  }

  /// Update typing status from another user (received from network)
  void updateUserTypingStatus({
    required String conversationId,
    required String userId,
    required String userName,
    required bool isTyping,
  }) {
    final safeConversationId = InputValidator.safeString(conversationId);
    final safeUserId = InputValidator.safeString(userId);
    final safeUserName = InputValidator.safeString(userName);

    if (safeConversationId.isEmpty || safeUserId.isEmpty) return;

    // Initialize sets if they don't exist
    _typingUsers.putIfAbsent(safeConversationId, () => <String>{});
    _typingUserNames.putIfAbsent(safeConversationId, () => <String>{});

    if (isTyping) {
      _typingUsers[safeConversationId]!.add(safeUserId);
      if (safeUserName.isNotEmpty) {
        _typingUserNames[safeConversationId]!.add(safeUserName);
      }

      // Auto-clear this user's typing status after 5 seconds
      Timer(const Duration(seconds: 5), () {
        _typingUsers[safeConversationId]?.remove(safeUserId);
        _typingUserNames[safeConversationId]?.remove(safeUserName);
        notifyListeners();
      });
    } else {
      _typingUsers[safeConversationId]?.remove(safeUserId);
      _typingUserNames[safeConversationId]?.remove(safeUserName);
    }

    notifyListeners();
  }

  /// Clear all typing indicators for a conversation
  void clearConversationTyping(String conversationId) {
    final safeId = InputValidator.safeString(conversationId);

    _typingUsers.remove(safeId);
    _typingUserNames.remove(safeId);
    _typingTimers[safeId]?.cancel();
    _typingTimers.remove(safeId);
    _currentUserTyping.remove(safeId);

    notifyListeners();
  }

  /// Handle text input changes (call this from TextField onChange)
  Future<void> handleTextInput(String conversationId, String text) async {
    final safeId = InputValidator.safeString(conversationId);
    final safeText = InputValidator.safeString(text);

    if (safeText.isNotEmpty && !isCurrentUserTyping(safeId)) {
      // User started typing
      await startTyping(safeId);
    } else if (safeText.isEmpty && isCurrentUserTyping(safeId)) {
      // User cleared input
      await stopTyping(safeId);
    } else if (safeText.isNotEmpty && isCurrentUserTyping(safeId)) {
      // User is still typing - refresh the timer
      await startTyping(safeId);
    }
  }

  /// Handle message sent (call this when user sends a message)
  Future<void> handleMessageSent(String conversationId) async {
    await stopTyping(conversationId);
  }

  /// Get typing indicator statistics for debugging
  Map<String, dynamic> getTypingStats() {
    return {
      'activeConversations': _typingUsers.keys.length,
      'totalTypingUsers':
          _typingUsers.values.fold<int>(0, (sum, users) => sum + users.length),
      'currentUserTypingIn': _currentUserTyping.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList(),
    };
  }

  /// Dispose and cleanup all timers
  @override
  void dispose() {
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    _typingUsers.clear();
    _typingUserNames.clear();
    _currentUserTyping.clear();
    super.dispose();
  }

  // Private methods

  Future<void> _broadcastTypingStatus(
      String conversationId, bool isTyping) async {
    final wsClient = AppInit.wsClient;
    if (wsClient == null || !AppInit.isWebSocketConnected) {
      LogManager.debug(
          '[Typing] WebSocket unavailable; typing broadcast deferred: $conversationId');
      return;
    }

    wsClient.send(WsEnvelope(
      op: 'chat.typing',
      ts: DateTime.now().millisecondsSinceEpoch,
      data: {
        'conversationId': conversationId,
        'isTyping': isTyping,
      },
    ));
  }
}

/// Extension methods for easy integration with text fields
extension TypingIndicatorTextFieldExtension on TypingIndicatorService {
  /// Create a text change handler for a specific conversation
  Function(String) createTextChangeHandler(String conversationId) {
    return (String text) => handleTextInput(conversationId, text);
  }

  /// Create a submit handler for a specific conversation
  Function() createSubmitHandler(String conversationId) {
    return () => handleMessageSent(conversationId);
  }
}

/// Widget helper class for typing indicator UI
class TypingIndicatorData {
  final String text;
  final bool isVisible;
  final int userCount;
  final Duration animationDuration;

  const TypingIndicatorData({
    required this.text,
    required this.isVisible,
    required this.userCount,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  /// Create from service data
  factory TypingIndicatorData.fromService(
    TypingIndicatorService service,
    String conversationId,
  ) {
    final typingUsers = service.getTypingUsers(conversationId);
    final typingText = service.getTypingText(conversationId);

    return TypingIndicatorData(
      text: typingText,
      isVisible: typingUsers.isNotEmpty,
      userCount: typingUsers.length,
    );
  }

  /// Create empty/hidden state
  factory TypingIndicatorData.hidden() {
    return const TypingIndicatorData(
      text: '',
      isVisible: false,
      userCount: 0,
    );
  }
}
