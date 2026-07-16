import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/social/friend_message_bridge.dart';
import 'package:synaptix/core/services/social/conversation_storage_service.dart';
import 'package:synaptix/core/services/storage/message_storage_service.dart';
import 'package:synaptix/game/models/message_models.dart';

void main() {
  late MessageStorageService msgStorage;
  late ConversationStorageService convStorage;
  late FriendMessageBridge bridge;

  setUp(() {
    msgStorage = MessageStorageService();
    convStorage = ConversationStorageService();
    bridge = FriendMessageBridge(
      messageStorage: msgStorage,
      conversationStorage: convStorage,
    );
  });

  // -------------------------------------------------------------------------
  // onFriendRequestSent
  // -------------------------------------------------------------------------

  group('onFriendRequestSent', () {
    test('saves a message of type friendRequest', () async {
      await bridge.onFriendRequestSent(
        senderId: 'user_a',
        senderName: 'Alice',
        recipientId: 'user_b',
        requestId: 'req_1',
      );
      final convId = 'conv_user_a_user_b';
      final msgs =
          msgStorage.getMessagesByType(convId, MessageType.friendRequest);
      expect(msgs, hasLength(1));
    });

    test('message senderId matches caller senderId', () async {
      await bridge.onFriendRequestSent(
        senderId: 'user_a',
        senderName: 'Alice',
        recipientId: 'user_b',
        requestId: 'req_1',
      );
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.friendRequest)
          .first;
      expect(msg.senderId, 'user_a');
      expect(msg.senderName, 'Alice');
    });

    test('default content is "Sent you a friend request"', () async {
      await bridge.onFriendRequestSent(
        senderId: 'user_a',
        senderName: 'Alice',
        recipientId: 'user_b',
        requestId: 'req_1',
      );
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.friendRequest)
          .first;
      expect(msg.content, 'Sent you a friend request');
    });

    test('custom message overrides default content', () async {
      await bridge.onFriendRequestSent(
        senderId: 'user_a',
        senderName: 'Alice',
        recipientId: 'user_b',
        requestId: 'req_1',
        message: 'Hey, let\'s be friends!',
      );
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.friendRequest)
          .first;
      expect(msg.content, 'Hey, let\'s be friends!');
    });

    test('message metadata contains requestId', () async {
      await bridge.onFriendRequestSent(
        senderId: 'user_a',
        senderName: 'Alice',
        recipientId: 'user_b',
        requestId: 'req_42',
      );
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.friendRequest)
          .first;
      expect(msg.metadata?['requestId'], 'req_42');
    });

    test('creates conversation if it does not exist', () async {
      expect(convStorage.getConversationById('conv_user_a_user_b'), isNull);
      await bridge.onFriendRequestSent(
        senderId: 'user_a',
        senderName: 'Alice',
        recipientId: 'user_b',
        requestId: 'req_1',
      );
      expect(convStorage.getConversationById('conv_user_a_user_b'), isNotNull);
    });

    test('conversation ID is sorted: user_b < user_a → conv_user_a_user_b',
        () async {
      // Sender and recipient are sorted alphabetically
      await bridge.onFriendRequestSent(
        senderId: 'user_b',
        senderName: 'Bob',
        recipientId: 'user_a',
        requestId: 'req_99',
      );
      final conv = convStorage.getConversationById('conv_user_a_user_b');
      expect(conv, isNotNull);
    });

    test('updates conversation last message', () async {
      await bridge.onFriendRequestSent(
        senderId: 'user_a',
        senderName: 'Alice',
        recipientId: 'user_b',
        requestId: 'req_1',
      );
      final conv = convStorage.getConversationById('conv_user_a_user_b')!;
      expect(conv.lastMessageId, isNotNull);
    });

    test('message status is sent', () async {
      await bridge.onFriendRequestSent(
        senderId: 'user_a',
        senderName: 'Alice',
        recipientId: 'user_b',
        requestId: 'req_1',
      );
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.friendRequest)
          .first;
      expect(msg.status, MessageStatus.sent);
    });
  });

  // -------------------------------------------------------------------------
  // onFriendRequestAccepted
  // -------------------------------------------------------------------------

  group('onFriendRequestAccepted', () {
    test('saves a message of type friendAccepted', () async {
      await bridge.onFriendRequestAccepted(
        accepterId: 'user_b',
        accepterName: 'Bob',
        requesterId: 'user_a',
      );
      final convId = 'conv_user_a_user_b';
      final msgs =
          msgStorage.getMessagesByType(convId, MessageType.friendAccepted);
      expect(msgs, hasLength(1));
    });

    test('message senderId is accepterId', () async {
      await bridge.onFriendRequestAccepted(
        accepterId: 'user_b',
        accepterName: 'Bob',
        requesterId: 'user_a',
      );
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.friendAccepted)
          .first;
      expect(msg.senderId, 'user_b');
      expect(msg.senderName, 'Bob');
    });

    test('message content is "You are now friends!"', () async {
      await bridge.onFriendRequestAccepted(
        accepterId: 'user_b',
        accepterName: 'Bob',
        requesterId: 'user_a',
      );
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.friendAccepted)
          .first;
      expect(msg.content, 'You are now friends!');
    });

    test('message status is sent', () async {
      await bridge.onFriendRequestAccepted(
        accepterId: 'user_b',
        accepterName: 'Bob',
        requesterId: 'user_a',
      );
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.friendAccepted)
          .first;
      expect(msg.status, MessageStatus.sent);
    });

    test('message conversationId uses sorted IDs', () async {
      await bridge.onFriendRequestAccepted(
        accepterId: 'user_b',
        accepterName: 'Bob',
        requesterId: 'user_a',
      );
      final msg = msgStorage
          .getMessagesByType('conv_user_a_user_b', MessageType.friendAccepted)
          .first;
      expect(msg.conversationId, 'conv_user_a_user_b');
    });
  });

  // -------------------------------------------------------------------------
  // Full flow: request sent then accepted
  // -------------------------------------------------------------------------

  group('full friend request flow', () {
    test('sent then accepted produces two messages in same conversation',
        () async {
      await bridge.onFriendRequestSent(
        senderId: 'user_a',
        senderName: 'Alice',
        recipientId: 'user_b',
        requestId: 'req_1',
      );
      await bridge.onFriendRequestAccepted(
        accepterId: 'user_b',
        accepterName: 'Bob',
        requesterId: 'user_a',
      );
      final allMessages =
          msgStorage.getMessagesByConversation('conv_user_a_user_b');
      expect(allMessages, hasLength(2));
      expect(allMessages.map((m) => m.type).toList(), [
        MessageType.friendRequest,
        MessageType.friendAccepted,
      ]);
    });
  });
}
