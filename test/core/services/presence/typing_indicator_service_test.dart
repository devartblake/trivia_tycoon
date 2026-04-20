import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/presence/typing_indicator_service.dart';

// ---------------------------------------------------------------------------
// Notes on test design
// ---------------------------------------------------------------------------
// TypingIndicatorService is a singleton (factory constructor).
// - We do NOT call dispose() in tearDown (that would invalidate the singleton's
//   ChangeNotifier, causing subsequent notifyListeners() calls to throw).
// - Instead each test uses a unique conversationId so state cannot bleed.
// - tearDown calls clearConversationTyping() to cancel timers and reset maps.
// - _broadcastTypingStatus() is a no-op in tests (AppInit.wsClient is null).
// ---------------------------------------------------------------------------

void main() {
  // Shared singleton instance
  final svc = TypingIndicatorService();

  // Unique counter so each test gets its own conversationId
  int _counter = 0;
  String nextId() => 'conv-test-${_counter++}';

  // -------------------------------------------------------------------------
  // isAnyoneTyping — initial state
  // -------------------------------------------------------------------------

  group('TypingIndicatorService.isAnyoneTyping — initial state', () {
    test('returns false for an unseen conversation', () {
      expect(svc.isAnyoneTyping('conv-unseen-${_counter++}'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // isCurrentUserTyping — initial state
  // -------------------------------------------------------------------------

  group('TypingIndicatorService.isCurrentUserTyping — initial state', () {
    test('returns false before startTyping has been called', () {
      expect(svc.isCurrentUserTyping('conv-unseen-${_counter++}'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // startTyping()
  // -------------------------------------------------------------------------

  group('TypingIndicatorService.startTyping()', () {
    test('isCurrentUserTyping returns true after startTyping', () async {
      final id = nextId();
      addTearDown(() => svc.clearConversationTyping(id));

      await svc.startTyping(id);
      expect(svc.isCurrentUserTyping(id), isTrue);
    });

    test('calling startTyping on empty conversationId does nothing', () async {
      await svc.startTyping(''); // safeId is empty → returns early
      expect(svc.isCurrentUserTyping(''), isFalse);
    });

    test('startTyping can be called multiple times without error', () async {
      final id = nextId();
      addTearDown(() => svc.clearConversationTyping(id));

      await svc.startTyping(id);
      await svc.startTyping(id); // refreshes timer
      expect(svc.isCurrentUserTyping(id), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // stopTyping()
  // -------------------------------------------------------------------------

  group('TypingIndicatorService.stopTyping()', () {
    test('isCurrentUserTyping returns false after stopTyping', () async {
      final id = nextId();
      addTearDown(() => svc.clearConversationTyping(id));

      await svc.startTyping(id);
      await svc.stopTyping(id);
      expect(svc.isCurrentUserTyping(id), isFalse);
    });

    test('stopTyping on a conversation not yet started does not throw',
        () async {
      final id = nextId();
      await expectLater(svc.stopTyping(id), completes);
    });
  });

  // -------------------------------------------------------------------------
  // updateUserTypingStatus() — peer typing
  // -------------------------------------------------------------------------

  group('TypingIndicatorService.updateUserTypingStatus()', () {
    test('isAnyoneTyping returns true after peer starts typing', () {
      final id = nextId();
      addTearDown(() => svc.clearConversationTyping(id));

      svc.updateUserTypingStatus(
        conversationId: id,
        userId: 'user-42',
        userName: 'Alice',
        isTyping: true,
      );
      expect(svc.isAnyoneTyping(id), isTrue);
    });

    test('getTypingUsers returns the peer userId', () {
      final id = nextId();
      addTearDown(() => svc.clearConversationTyping(id));

      svc.updateUserTypingStatus(
        conversationId: id,
        userId: 'user-99',
        userName: 'Bob',
        isTyping: true,
      );
      expect(svc.getTypingUsers(id), contains('user-99'));
    });

    test('isAnyoneTyping returns false after peer stops typing', () {
      final id = nextId();
      addTearDown(() => svc.clearConversationTyping(id));

      svc.updateUserTypingStatus(
        conversationId: id,
        userId: 'user-10',
        userName: 'Carol',
        isTyping: true,
      );
      svc.updateUserTypingStatus(
        conversationId: id,
        userId: 'user-10',
        userName: 'Carol',
        isTyping: false,
      );
      expect(svc.isAnyoneTyping(id), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // getTypingText()
  // -------------------------------------------------------------------------

  group('TypingIndicatorService.getTypingText()', () {
    test('returns empty string when no one is typing', () {
      final id = nextId();
      expect(svc.getTypingText(id), isEmpty);
    });

    test('returns "<name> is typing..." for a single typer', () {
      final id = nextId();
      addTearDown(() => svc.clearConversationTyping(id));

      svc.updateUserTypingStatus(
        conversationId: id,
        userId: 'u1',
        userName: 'Dave',
        isTyping: true,
      );
      expect(svc.getTypingText(id), contains('is typing...'));
    });
  });

  // -------------------------------------------------------------------------
  // handleTextInput()
  // -------------------------------------------------------------------------

  group('TypingIndicatorService.handleTextInput()', () {
    test('non-empty text starts typing for current user', () async {
      final id = nextId();
      addTearDown(() => svc.clearConversationTyping(id));

      await svc.handleTextInput(id, 'hello');
      expect(svc.isCurrentUserTyping(id), isTrue);
    });

    test('empty text stops typing for current user', () async {
      final id = nextId();
      addTearDown(() => svc.clearConversationTyping(id));

      await svc.handleTextInput(id, 'hi');
      await svc.handleTextInput(id, '');
      expect(svc.isCurrentUserTyping(id), isFalse);
    });

    test('repeated non-empty text keeps typing active', () async {
      final id = nextId();
      addTearDown(() => svc.clearConversationTyping(id));

      await svc.handleTextInput(id, 'hi');
      await svc.handleTextInput(id, 'hi there');
      expect(svc.isCurrentUserTyping(id), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // handleMessageSent()
  // -------------------------------------------------------------------------

  group('TypingIndicatorService.handleMessageSent()', () {
    test('stops typing for current user', () async {
      final id = nextId();
      addTearDown(() => svc.clearConversationTyping(id));

      await svc.startTyping(id);
      await svc.handleMessageSent(id);
      expect(svc.isCurrentUserTyping(id), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // clearConversationTyping()
  // -------------------------------------------------------------------------

  group('TypingIndicatorService.clearConversationTyping()', () {
    test('clears current-user typing status', () async {
      final id = nextId();
      await svc.startTyping(id);
      svc.clearConversationTyping(id);
      expect(svc.isCurrentUserTyping(id), isFalse);
    });

    test('clears peer typing users', () {
      final id = nextId();
      svc.updateUserTypingStatus(
        conversationId: id,
        userId: 'peer',
        userName: 'Eve',
        isTyping: true,
      );
      svc.clearConversationTyping(id);
      expect(svc.isAnyoneTyping(id), isFalse);
      expect(svc.getTypingUsers(id), isEmpty);
    });

    test('clearing a conversation that was never used does not throw', () {
      expect(() => svc.clearConversationTyping('conv-never-used-${_counter++}'),
          returnsNormally);
    });
  });

  // -------------------------------------------------------------------------
  // getTypingStats()
  // -------------------------------------------------------------------------

  group('TypingIndicatorService.getTypingStats()', () {
    test('returns a map with expected keys', () {
      final stats = svc.getTypingStats();
      expect(stats.containsKey('activeConversations'), isTrue);
      expect(stats.containsKey('totalTypingUsers'), isTrue);
      expect(stats.containsKey('currentUserTypingIn'), isTrue);
    });
  });
}
