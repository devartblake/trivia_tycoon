import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/social/friend_list_item_dto.dart';
import 'package:trivia_tycoon/core/models/social/friend_request_dto.dart';
import 'package:trivia_tycoon/core/models/social/friend_suggestion_dto.dart';
import 'package:trivia_tycoon/core/models/social/paginated_social_response.dart';

// ─── FriendListItemDto helpers ────────────────────────────────────────────────

Map<String, dynamic> _friendJson({
  String friendPlayerId = 'fp1',
  String displayName = 'Alice',
  String username = 'alice42',
  String? avatarUrl,
  bool isOnline = false,
  String? lastSeenUtc,
  String? sinceUtc,
}) =>
    {
      'friendPlayerId': friendPlayerId,
      'displayName': displayName,
      'username': username,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      if (lastSeenUtc != null) 'lastSeenUtc': lastSeenUtc,
      if (sinceUtc != null) 'sinceUtc': sinceUtc,
    };

// ─── FriendRequestDto helpers ─────────────────────────────────────────────────

Map<String, dynamic> _requestJson({
  String requestId = 'req1',
  String fromPlayerId = 'fp1',
  String toPlayerId = 'tp1',
  String status = 'Pending',
  String? createdAtUtc,
  String? respondedAtUtc,
  String? senderDisplayName,
  String? senderUsername,
  String? senderAvatarUrl,
}) =>
    {
      'requestId': requestId,
      'fromPlayerId': fromPlayerId,
      'toPlayerId': toPlayerId,
      'status': status,
      if (createdAtUtc != null) 'createdAtUtc': createdAtUtc,
      if (respondedAtUtc != null) 'respondedAtUtc': respondedAtUtc,
      if (senderDisplayName != null) 'senderDisplayName': senderDisplayName,
      if (senderUsername != null) 'senderUsername': senderUsername,
      if (senderAvatarUrl != null) 'senderAvatarUrl': senderAvatarUrl,
    };

// ─── FriendSuggestionDto helpers ──────────────────────────────────────────────

Map<String, dynamic> _suggestionJson({
  String id = 'sg1',
  String displayName = 'Bob',
  String username = 'bob99',
  String? avatarUrl,
  int mutualFriendCount = 0,
  String reason = 'mutual_friends',
}) =>
    {
      'id': id,
      'displayName': displayName,
      'username': username,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'mutualFriendCount': mutualFriendCount,
      'reason': reason,
    };

void main() {
  // =========================================================================
  // FriendListItemDto
  // =========================================================================

  group('FriendListItemDto.fromJson — scalar fields', () {
    test('parses friendPlayerId', () {
      expect(
          FriendListItemDto.fromJson(_friendJson(friendPlayerId: 'uid_x'))
              .friendPlayerId,
          'uid_x');
    });

    test('friendPlayerId defaults to "" when absent', () {
      final json = _friendJson();
      json.remove('friendPlayerId');
      expect(FriendListItemDto.fromJson(json).friendPlayerId, '');
    });

    test('parses displayName', () {
      expect(
          FriendListItemDto.fromJson(_friendJson(displayName: 'Charlie'))
              .displayName,
          'Charlie');
    });

    test('displayName falls back to username when absent', () {
      final json = _friendJson();
      json.remove('displayName');
      json['username'] = 'charlie123';
      expect(FriendListItemDto.fromJson(json).displayName, 'charlie123');
    });

    test('parses username', () {
      expect(
          FriendListItemDto.fromJson(_friendJson(username: 'alice_q')).username,
          'alice_q');
    });

    test('username falls back to displayName when absent', () {
      final json = _friendJson(displayName: 'FallbackName');
      json.remove('username');
      expect(FriendListItemDto.fromJson(json).username, 'FallbackName');
    });

    test('parses avatarUrl', () {
      expect(
          FriendListItemDto.fromJson(
                  _friendJson(avatarUrl: 'https://img/av.png'))
              .avatarUrl,
          'https://img/av.png');
    });

    test('avatarUrl is null when absent', () {
      expect(FriendListItemDto.fromJson(_friendJson()).avatarUrl, isNull);
    });

    test('parses isOnline', () {
      expect(FriendListItemDto.fromJson(_friendJson(isOnline: true)).isOnline,
          isTrue);
    });

    test('isOnline defaults to false when absent', () {
      final json = _friendJson();
      json.remove('isOnline');
      expect(FriendListItemDto.fromJson(json).isOnline, isFalse);
    });
  });

  group('FriendListItemDto.fromJson — DateTime fields', () {
    test('parses lastSeenUtc', () {
      final dto = FriendListItemDto.fromJson(
          _friendJson(lastSeenUtc: '2025-06-10T08:00:00.000Z'));
      expect(dto.lastSeenUtc, isNotNull);
      expect(dto.lastSeenUtc!.month, 6);
    });

    test('lastSeenUtc is null when absent', () {
      expect(FriendListItemDto.fromJson(_friendJson()).lastSeenUtc, isNull);
    });

    test('parses sinceUtc', () {
      final dto = FriendListItemDto.fromJson(
          _friendJson(sinceUtc: '2024-01-15T00:00:00.000Z'));
      expect(dto.sinceUtc, isNotNull);
      expect(dto.sinceUtc!.year, 2024);
    });

    test('sinceUtc is null when absent', () {
      expect(FriendListItemDto.fromJson(_friendJson()).sinceUtc, isNull);
    });
  });

  group('FriendListItemDto.toJson', () {
    test('round-trip preserves all fields', () {
      final original = FriendListItemDto.fromJson(_friendJson(
        friendPlayerId: 'fp42',
        displayName: 'Delta',
        username: 'delta_x',
        avatarUrl: 'https://img/d.png',
        isOnline: true,
        lastSeenUtc: '2025-06-01T00:00:00.000Z',
      ));
      final restored = FriendListItemDto.fromJson(original.toJson());
      expect(restored.friendPlayerId, original.friendPlayerId);
      expect(restored.displayName, original.displayName);
      expect(restored.isOnline, original.isOnline);
      expect(restored.avatarUrl, original.avatarUrl);
    });
  });

  // =========================================================================
  // FriendRequestDto
  // =========================================================================

  group('FriendRequestDto.fromJson — scalar fields', () {
    test('parses requestId', () {
      expect(
          FriendRequestDto.fromJson(_requestJson(requestId: 'r99')).requestId,
          'r99');
    });

    test('requestId defaults to "" when absent', () {
      final json = _requestJson();
      json.remove('requestId');
      expect(FriendRequestDto.fromJson(json).requestId, '');
    });

    test('parses fromPlayerId', () {
      expect(
          FriendRequestDto.fromJson(_requestJson(fromPlayerId: 'from_x'))
              .fromPlayerId,
          'from_x');
    });

    test('parses toPlayerId', () {
      expect(
          FriendRequestDto.fromJson(_requestJson(toPlayerId: 'to_y'))
              .toPlayerId,
          'to_y');
    });

    test('parses status', () {
      expect(FriendRequestDto.fromJson(_requestJson(status: 'Accepted')).status,
          'Accepted');
    });

    test('status defaults to "Pending" when absent', () {
      final json = _requestJson();
      json.remove('status');
      expect(FriendRequestDto.fromJson(json).status, 'Pending');
    });

    test('parses senderDisplayName', () {
      expect(
          FriendRequestDto.fromJson(_requestJson(senderDisplayName: 'Eve'))
              .senderDisplayName,
          'Eve');
    });

    test('senderDisplayName is null when absent', () {
      expect(
          FriendRequestDto.fromJson(_requestJson()).senderDisplayName, isNull);
    });

    test('parses senderUsername', () {
      expect(
          FriendRequestDto.fromJson(_requestJson(senderUsername: 'eve_q'))
              .senderUsername,
          'eve_q');
    });

    test('parses senderAvatarUrl', () {
      expect(
          FriendRequestDto.fromJson(
                  _requestJson(senderAvatarUrl: 'https://img/e.png'))
              .senderAvatarUrl,
          'https://img/e.png');
    });
  });

  group('FriendRequestDto.fromJson — DateTime fields', () {
    test('parses createdAtUtc', () {
      final dto = FriendRequestDto.fromJson(
          _requestJson(createdAtUtc: '2025-05-01T12:00:00.000Z'));
      expect(dto.createdAtUtc, isNotNull);
      expect(dto.createdAtUtc!.month, 5);
    });

    test('createdAtUtc is null when absent', () {
      expect(FriendRequestDto.fromJson(_requestJson()).createdAtUtc, isNull);
    });

    test('parses respondedAtUtc', () {
      final dto = FriendRequestDto.fromJson(
          _requestJson(respondedAtUtc: '2025-05-02T08:00:00.000Z'));
      expect(dto.respondedAtUtc, isNotNull);
      expect(dto.respondedAtUtc!.day, 2);
    });

    test('respondedAtUtc is null when absent', () {
      expect(FriendRequestDto.fromJson(_requestJson()).respondedAtUtc, isNull);
    });
  });

  group('FriendRequestDto — isPending', () {
    test('true when status is "pending" (case-insensitive)', () {
      expect(
          FriendRequestDto.fromJson(_requestJson(status: 'pending')).isPending,
          isTrue);
    });

    test('true when status is "Pending"', () {
      expect(
          FriendRequestDto.fromJson(_requestJson(status: 'Pending')).isPending,
          isTrue);
    });

    test('false when status is "Accepted"', () {
      expect(
          FriendRequestDto.fromJson(_requestJson(status: 'Accepted')).isPending,
          isFalse);
    });

    test('false when status is "Declined"', () {
      expect(
          FriendRequestDto.fromJson(_requestJson(status: 'Declined')).isPending,
          isFalse);
    });
  });

  group('FriendRequestDto.toJson', () {
    test('serializes createdAtUtc as ISO string when set', () {
      final dto = FriendRequestDto.fromJson(
          _requestJson(createdAtUtc: '2025-06-01T00:00:00.000Z'));
      expect(dto.toJson()['createdAtUtc'], isA<String>());
    });

    test('round-trip preserves requestId and status', () {
      final original = FriendRequestDto.fromJson(
          _requestJson(requestId: 'req42', status: 'Declined'));
      final restored = FriendRequestDto.fromJson(original.toJson());
      expect(restored.requestId, 'req42');
      expect(restored.status, 'Declined');
    });
  });

  // =========================================================================
  // FriendSuggestionDto
  // =========================================================================

  group('FriendSuggestionDto.fromJson — scalar fields', () {
    test('parses id', () {
      expect(
          FriendSuggestionDto.fromJson(_suggestionJson(id: 'sg99')).id, 'sg99');
    });

    test('id defaults to "" when absent', () {
      final json = _suggestionJson();
      json.remove('id');
      expect(FriendSuggestionDto.fromJson(json).id, '');
    });

    test('parses displayName', () {
      expect(
          FriendSuggestionDto.fromJson(_suggestionJson(displayName: 'Dan'))
              .displayName,
          'Dan');
    });

    test('displayName falls back to username', () {
      final json = _suggestionJson();
      json.remove('displayName');
      json['username'] = 'dan_fallback';
      expect(FriendSuggestionDto.fromJson(json).displayName, 'dan_fallback');
    });

    test('parses username', () {
      expect(
          FriendSuggestionDto.fromJson(_suggestionJson(username: 'dan42'))
              .username,
          'dan42');
    });

    test('username falls back to displayName', () {
      final json = _suggestionJson(displayName: 'FallbackDisplay');
      json.remove('username');
      expect(FriendSuggestionDto.fromJson(json).username, 'FallbackDisplay');
    });

    test('parses avatarUrl', () {
      expect(
          FriendSuggestionDto.fromJson(
                  _suggestionJson(avatarUrl: 'https://img/d.png'))
              .avatarUrl,
          'https://img/d.png');
    });

    test('avatarUrl is null when absent', () {
      expect(FriendSuggestionDto.fromJson(_suggestionJson()).avatarUrl, isNull);
    });

    test('parses mutualFriendCount', () {
      expect(
          FriendSuggestionDto.fromJson(_suggestionJson(mutualFriendCount: 5))
              .mutualFriendCount,
          5);
    });

    test('mutualFriendCount defaults to 0 when absent', () {
      final json = _suggestionJson();
      json.remove('mutualFriendCount');
      expect(FriendSuggestionDto.fromJson(json).mutualFriendCount, 0);
    });

    test('parses reason', () {
      expect(
          FriendSuggestionDto.fromJson(_suggestionJson(reason: 'same_league'))
              .reason,
          'same_league');
    });

    test('reason defaults to "" when absent', () {
      final json = _suggestionJson();
      json.remove('reason');
      expect(FriendSuggestionDto.fromJson(json).reason, '');
    });
  });

  group('FriendSuggestionDto — hasMutualFriends', () {
    test('true when mutualFriendCount > 0', () {
      expect(
          FriendSuggestionDto.fromJson(_suggestionJson(mutualFriendCount: 3))
              .hasMutualFriends,
          isTrue);
    });

    test('false when mutualFriendCount = 0', () {
      expect(
          FriendSuggestionDto.fromJson(_suggestionJson(mutualFriendCount: 0))
              .hasMutualFriends,
          isFalse);
    });
  });

  group('FriendSuggestionDto.toJson', () {
    test('round-trip preserves all fields', () {
      final original = FriendSuggestionDto.fromJson(_suggestionJson(
        id: 'sg5',
        displayName: 'Frank',
        username: 'frank_q',
        avatarUrl: 'https://img/f.png',
        mutualFriendCount: 2,
        reason: 'nearby',
      ));
      final restored = FriendSuggestionDto.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.mutualFriendCount, original.mutualFriendCount);
      expect(restored.reason, original.reason);
    });
  });

  // =========================================================================
  // PaginatedSocialResponse
  // =========================================================================

  group('PaginatedSocialResponse.fromJson', () {
    Map<String, dynamic> _pageJson({
      int page = 1,
      int pageSize = 10,
      int total = 30,
      int? totalPages,
      List<Map<String, dynamic>>? items,
    }) =>
        {
          'page': page,
          'pageSize': pageSize,
          'total': total,
          if (totalPages != null) 'totalPages': totalPages,
          'items': items ?? [_friendJson()],
        };

    test('parses page', () {
      final resp = PaginatedSocialResponse.fromJson(
          _pageJson(page: 2), FriendListItemDto.fromJson);
      expect(resp.page, 2);
    });

    test('parses pageSize', () {
      final resp = PaginatedSocialResponse.fromJson(
          _pageJson(pageSize: 25), FriendListItemDto.fromJson);
      expect(resp.pageSize, 25);
    });

    test('parses total', () {
      final resp = PaginatedSocialResponse.fromJson(
          _pageJson(total: 100), FriendListItemDto.fromJson);
      expect(resp.total, 100);
    });

    test('parses totalPages when provided', () {
      final resp = PaginatedSocialResponse.fromJson(
          _pageJson(total: 30, pageSize: 10, totalPages: 3),
          FriendListItemDto.fromJson);
      expect(resp.totalPages, 3);
    });

    test('infers totalPages when absent (ceil division)', () {
      final resp = PaginatedSocialResponse.fromJson(
          _pageJson(total: 25, pageSize: 10), FriendListItemDto.fromJson);
      expect(resp.totalPages, 3);
    });

    test('parses items', () {
      final resp = PaginatedSocialResponse.fromJson(
          _pageJson(items: [
            _friendJson(friendPlayerId: 'fp1'),
            _friendJson(friendPlayerId: 'fp2')
          ]),
          FriendListItemDto.fromJson);
      expect(resp.items.length, 2);
      expect(resp.items.first.friendPlayerId, 'fp1');
    });

    test('empty items list when items absent', () {
      final json = _pageJson();
      json.remove('items');
      final resp =
          PaginatedSocialResponse.fromJson(json, FriendListItemDto.fromJson);
      expect(resp.items, isEmpty);
    });

    test('page defaults to 1 when absent', () {
      final json = _pageJson();
      json.remove('page');
      final resp =
          PaginatedSocialResponse.fromJson(json, FriendListItemDto.fromJson);
      expect(resp.page, 1);
    });
  });

  group('PaginatedSocialResponse — hasNext / hasPrevious', () {
    test('hasNext true when page < totalPages', () {
      final resp = PaginatedSocialResponse<FriendListItemDto>(
          items: [], page: 1, pageSize: 10, total: 30, totalPages: 3);
      expect(resp.hasNext, isTrue);
    });

    test('hasNext false when on last page', () {
      final resp = PaginatedSocialResponse<FriendListItemDto>(
          items: [], page: 3, pageSize: 10, total: 30, totalPages: 3);
      expect(resp.hasNext, isFalse);
    });

    test('hasPrevious false on first page', () {
      final resp = PaginatedSocialResponse<FriendListItemDto>(
          items: [], page: 1, pageSize: 10, total: 30, totalPages: 3);
      expect(resp.hasPrevious, isFalse);
    });

    test('hasPrevious true when page > 1', () {
      final resp = PaginatedSocialResponse<FriendListItemDto>(
          items: [], page: 2, pageSize: 10, total: 30, totalPages: 3);
      expect(resp.hasPrevious, isTrue);
    });
  });

  group('PaginatedSocialResponse.toJson', () {
    test('round-trip preserves page, pageSize, total', () {
      final original = PaginatedSocialResponse.fromJson({
        'page': 2,
        'pageSize': 5,
        'total': 15,
        'totalPages': 3,
        'items': [_friendJson()]
      }, FriendListItemDto.fromJson);
      final json = original.toJson((item) => item.toJson());
      expect(json['page'], 2);
      expect(json['pageSize'], 5);
      expect(json['total'], 15);
    });
  });
}
