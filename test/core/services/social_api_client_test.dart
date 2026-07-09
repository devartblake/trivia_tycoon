import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/social/friends_models.dart';
import 'package:trivia_tycoon/core/services/social/parties_models.dart';

/// Contract tests for the social DTO mappings.
///
/// The JSON fixtures mirror the backend DTO shapes in
/// Synaptix.Shared.Contracts/Dtos/SocialDtos.cs and AuthDtos.cs
/// (UserFriendsEndpoints / PartyEndpoints / UsersEndpoints.SearchUsers).
/// If the backend contract changes, these tests should fail first.
void main() {
  group('FriendsListResponse (FriendsListResponseDto)', () {
    test('parses backend envelope {page, pageSize, total, items}', () {
      final response = FriendsListResponse.fromJson({
        'page': 2,
        'pageSize': 20,
        'total': 41,
        'totalPages': 3,
        'items': [
          {
            'friendPlayerId': '11111111-1111-1111-1111-111111111111',
            'displayName': 'Quiz Queen',
            'username': 'quizqueen',
            'avatarUrl': 'https://cdn.example/q.png',
            'isOnline': true,
            'lastSeenUtc': '2026-07-08T10:00:00Z',
            'sinceUtc': '2026-06-01T09:30:00Z',
          },
        ],
      });

      expect(response.page, 2);
      expect(response.pageSize, 20);
      expect(response.totalCount, 41);
      expect(response.friends, hasLength(1));

      final friend = response.friends.first;
      expect(friend.friendId, '11111111-1111-1111-1111-111111111111');
      expect(friend.username, 'quizqueen');
      expect(friend.avatarUrl, 'https://cdn.example/q.png');
      expect(friend.isOnline, isTrue);
      expect(friend.connectedSinceUtc, DateTime.utc(2026, 6, 1, 9, 30));
    });

    test('parses empty/missing items safely', () {
      final response = FriendsListResponse.fromJson(const {});
      expect(response.friends, isEmpty);
      expect(response.totalCount, 0);
    });
  });

  group('FriendRequestsResponse (FriendRequestsDetailListResponseDto)', () {
    test('parses detail items with sender profile fields', () {
      final response = FriendRequestsResponse.fromJson({
        'page': 1,
        'pageSize': 50,
        'total': 1,
        'totalPages': 1,
        'items': [
          {
            'requestId': '22222222-2222-2222-2222-222222222222',
            'fromPlayerId': '33333333-3333-3333-3333-333333333333',
            'senderDisplayName': 'Brainiac',
            'senderUsername': 'brainiac42',
            'senderAvatarUrl': null,
            'toPlayerId': '44444444-4444-4444-4444-444444444444',
            'status': 'Pending',
            'createdAtUtc': '2026-07-07T18:45:00Z',
            'respondedAtUtc': null,
          },
        ],
      });

      expect(response.requests, hasLength(1));
      final request = response.requests.first;
      expect(request.requestId, '22222222-2222-2222-2222-222222222222');
      expect(request.fromPlayerId, '33333333-3333-3333-3333-333333333333');
      expect(request.fromUsername, 'brainiac42');
      expect(request.fromAvatarUrl, isNull);
      expect(request.status, 'Pending');
      expect(request.sentAtUtc, DateTime.utc(2026, 7, 7, 18, 45));
    });
  });

  group('PlayerSearchResponse (UserSearchResponseDto)', () {
    test('parses search items {id, handle, username, tier}', () {
      final response = PlayerSearchResponse.fromJson({
        'page': 1,
        'pageSize': 20,
        'total': 2,
        'totalPages': 1,
        'items': [
          {
            'id': '55555555-5555-5555-5555-555555555555',
            'handle': 'triviafan',
            'displayName': 'triviafan',
            'username': 'triviafan',
            'avatarUrl': null,
            'country': 'US',
            'tier': 'silver-scholar',
            'mmr': 1200,
          },
          {
            'id': '66666666-6666-6666-6666-666666666666',
            'handle': 'quizzer',
            'displayName': 'quizzer',
            'username': 'quizzer',
            'avatarUrl': 'https://cdn.example/a.png',
            'country': null,
            'tier': null,
            'mmr': 0,
          },
        ],
      });

      expect(response.totalCount, 2);
      expect(response.results, hasLength(2));
      expect(
          response.results.first.playerId, '55555555-5555-5555-5555-555555555555');
      expect(response.results.first.username, 'triviafan');
      expect(response.results.first.level, 'silver-scholar');
      // Search endpoint does not provide relationship flags — safe defaults.
      expect(response.results.first.isFriend, isFalse);
      expect(response.results.first.hasOutgoingRequest, isFalse);
    });
  });

  group('SendFriendRequestRequest', () {
    test('serializes to backend body {targetUserId}', () {
      final body = SendFriendRequestRequest(
        targetPlayerId: '77777777-7777-7777-7777-777777777777',
      ).toJson();
      expect(body, {'targetUserId': '77777777-7777-7777-7777-777777777777'});
    });
  });

  group('PartyRoster (PartyRosterDto)', () {
    test('parses roster with members', () {
      final roster = PartyRoster.fromJson({
        'partyId': '88888888-8888-8888-8888-888888888888',
        'leaderPlayerId': '99999999-9999-9999-9999-999999999999',
        'status': 'Open',
        'members': [
          {
            'playerId': '99999999-9999-9999-9999-999999999999',
            'role': 'leader',
            'joinedAtUtc': '2026-07-08T12:00:00Z',
          },
        ],
      });

      expect(roster.partyId, '88888888-8888-8888-8888-888888888888');
      expect(roster.leaderPlayerId, '99999999-9999-9999-9999-999999999999');
      expect(roster.status, 'Open');
      expect(roster.members, hasLength(1));
      expect(roster.members.first.role, 'leader');
    });
  });

  group('PartyInvite (PartyInviteDto)', () {
    test('parses invite with pending status', () {
      final invite = PartyInvite.fromJson({
        'inviteId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'partyId': '88888888-8888-8888-8888-888888888888',
        'fromPlayerId': '99999999-9999-9999-9999-999999999999',
        'toPlayerId': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'status': 'Pending',
        'createdAtUtc': '2026-07-08T12:34:56Z',
        'respondedAtUtc': null,
      });

      expect(invite.inviteId, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
      expect(invite.status, 'Pending');
      expect(invite.respondedAtUtc, isNull);
      expect(invite.createdAtUtc, DateTime.utc(2026, 7, 8, 12, 34, 56));
    });
  });
}
