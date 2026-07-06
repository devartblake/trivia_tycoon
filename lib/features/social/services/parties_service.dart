import 'package:logging/logging.dart';
import '../../../core/services/social_api_client.dart';
import '../../../core/services/social/parties_models.dart';

/// Business logic layer for party/group operations.
///
/// Handles:
/// - Party creation and management
/// - Party invitations
/// - Member management
/// - Error handling and logging
class PartiesService {
  static final _log = Logger('PartiesService');

  final PartyApiClient _apiClient;

  PartiesService(this._apiClient);

  /// Create a new party
  Future<PartyResponse> createParty({
    required String name,
    String? description,
    int maxMembers = 4,
    String? gameMode,
  }) async {
    try {
      _log.info('Creating party: $name (max: $maxMembers)');
      final party = await _apiClient.createParty(
        name: name,
        description: description,
        maxMembers: maxMembers,
        gameMode: gameMode,
      );
      _log.fine('Party created: ${party.partyId}');
      return party;
    } catch (e, stackTrace) {
      _log.warning('Failed to create party', e, stackTrace);
      rethrow;
    }
  }

  /// Get party details
  Future<PartyDetailResponse> getPartyDetails(String partyId) async {
    try {
      _log.info('Fetching party details: $partyId');
      final party = await _apiClient.getPartyDetails(partyId);
      _log.fine('Fetched party: ${party.name} (${party.members.length} members)');
      return party;
    } catch (e, stackTrace) {
      _log.warning('Failed to fetch party details', e, stackTrace);
      rethrow;
    }
  }

  /// Get active parties for current player
  Future<List<PartyResponse>> getActiveParties({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      _log.info('Fetching active parties: page=$page pageSize=$pageSize');
      final response = await _apiClient.listParties(
        page: page,
        pageSize: pageSize,
        status: 'active',
      );
      _log.fine('Fetched ${response.parties.length} active parties');
      return response.parties;
    } catch (e, stackTrace) {
      _log.warning('Failed to fetch active parties', e, stackTrace);
      rethrow;
    }
  }

  /// Get all parties for current player
  Future<List<PartyResponse>> getAllParties({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      _log.info('Fetching all parties: page=$page pageSize=$pageSize');
      final response = await _apiClient.listParties(
        page: page,
        pageSize: pageSize,
      );
      _log.fine('Fetched ${response.parties.length} parties');
      return response.parties;
    } catch (e, stackTrace) {
      _log.warning('Failed to fetch parties', e, stackTrace);
      rethrow;
    }
  }

  /// Invite a friend to the party
  Future<void> inviteToParty({
    required String partyId,
    required String targetPlayerId,
  }) async {
    try {
      _log.info('Inviting $targetPlayerId to party $partyId');
      await _apiClient.inviteToParty(
        partyId: partyId,
        targetPlayerId: targetPlayerId,
      );
      _log.fine('Invitation sent successfully');
    } catch (e, stackTrace) {
      _log.warning('Failed to invite to party', e, stackTrace);
      rethrow;
    }
  }

  /// Accept a party invitation
  Future<void> acceptInvite(String inviteId) async {
    try {
      _log.info('Accepting party invite: $inviteId');
      await _apiClient.acceptPartyInvite(inviteId);
      _log.fine('Party invite accepted successfully');
    } catch (e, stackTrace) {
      _log.warning('Failed to accept party invite', e, stackTrace);
      rethrow;
    }
  }

  /// Decline a party invitation
  Future<void> declineInvite(String inviteId) async {
    try {
      _log.info('Declining party invite: $inviteId');
      await _apiClient.declinePartyInvite(inviteId);
      _log.fine('Party invite declined successfully');
    } catch (e, stackTrace) {
      _log.warning('Failed to decline party invite', e, stackTrace);
      rethrow;
    }
  }

  /// Leave a party
  Future<void> leaveParty(String partyId) async {
    try {
      _log.info('Leaving party: $partyId');
      await _apiClient.leaveParty(partyId);
      _log.fine('Left party successfully');
    } catch (e, stackTrace) {
      _log.warning('Failed to leave party', e, stackTrace);
      rethrow;
    }
  }

  /// Disband a party (owner only)
  Future<void> disbandParty(String partyId) async {
    try {
      _log.info('Disbanding party: $partyId');
      await _apiClient.disbandParty(partyId);
      _log.fine('Party disbanded successfully');
    } catch (e, stackTrace) {
      _log.warning('Failed to disband party', e, stackTrace);
      rethrow;
    }
  }
}
