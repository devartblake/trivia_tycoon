import 'package:logging/logging.dart';
import '../../../core/services/social_api_client.dart';
import '../../../core/services/social/parties_models.dart';

/// Business logic layer for party/group operations.
///
/// Wraps [PartyApiClient] (the verified /party backend surface). The party
/// endpoints take explicit player ids, so every mutating call requires the
/// current player's id from the caller.
class PartiesService {
  static final _log = Logger('PartiesService');

  final PartyApiClient _apiClient;

  PartiesService(this._apiClient);

  /// Create a new party led by [leaderPlayerId].
  Future<PartyRoster> createParty({required String leaderPlayerId}) async {
    try {
      _log.info('Creating party for leader: $leaderPlayerId');
      final roster = await _apiClient.createParty(
        leaderPlayerId: leaderPlayerId,
      );
      _log.fine('Party created: ${roster.partyId}');
      return roster;
    } catch (e, stackTrace) {
      _log.warning('Failed to create party', e, stackTrace);
      rethrow;
    }
  }

  /// Get party roster/details.
  Future<PartyRoster> getPartyRoster(String partyId) async {
    try {
      _log.info('Fetching party roster: $partyId');
      final roster = await _apiClient.getPartyRoster(partyId);
      _log.fine(
          'Fetched party ${roster.partyId} (${roster.members.length} members)');
      return roster;
    } catch (e, stackTrace) {
      _log.warning('Failed to fetch party roster', e, stackTrace);
      rethrow;
    }
  }

  /// List party invites for [playerId] (incoming by default).
  Future<List<PartyInvite>> listInvites({
    required String playerId,
    String box = 'incoming',
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      _log.info('Fetching party invites: player=$playerId box=$box');
      final invites = await _apiClient.listInvites(
        playerId: playerId,
        box: box,
        page: page,
        pageSize: pageSize,
      );
      _log.fine('Fetched ${invites.length} party invites');
      return invites;
    } catch (e, stackTrace) {
      _log.warning('Failed to fetch party invites', e, stackTrace);
      rethrow;
    }
  }

  /// Invite a player to the party.
  Future<void> inviteToParty({
    required String partyId,
    required String fromPlayerId,
    required String targetPlayerId,
  }) async {
    try {
      _log.info('Inviting $targetPlayerId to party $partyId');
      await _apiClient.inviteToParty(
        partyId: partyId,
        fromPlayerId: fromPlayerId,
        targetPlayerId: targetPlayerId,
      );
      _log.fine('Invitation sent successfully');
    } catch (e, stackTrace) {
      _log.warning('Failed to invite to party', e, stackTrace);
      rethrow;
    }
  }

  /// Accept a party invitation.
  Future<void> acceptInvite({
    required String inviteId,
    required String playerId,
  }) async {
    try {
      _log.info('Accepting party invite: $inviteId');
      await _apiClient.acceptInvite(inviteId: inviteId, playerId: playerId);
      _log.fine('Party invite accepted successfully');
    } catch (e, stackTrace) {
      _log.warning('Failed to accept party invite', e, stackTrace);
      rethrow;
    }
  }

  /// Decline a party invitation.
  Future<void> declineInvite({
    required String inviteId,
    required String playerId,
  }) async {
    try {
      _log.info('Declining party invite: $inviteId');
      await _apiClient.declineInvite(inviteId: inviteId, playerId: playerId);
      _log.fine('Party invite declined successfully');
    } catch (e, stackTrace) {
      _log.warning('Failed to decline party invite', e, stackTrace);
      rethrow;
    }
  }

  /// Leave a party.
  Future<void> leaveParty({
    required String partyId,
    required String playerId,
  }) async {
    try {
      _log.info('Leaving party: $partyId');
      await _apiClient.leaveParty(partyId: partyId, playerId: playerId);
      _log.fine('Left party successfully');
    } catch (e, stackTrace) {
      _log.warning('Failed to leave party', e, stackTrace);
      rethrow;
    }
  }
}
