import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../../dto/hub_event_dto.dart';
import 'hub_client_base.dart';

/// Persistent hub connected on login.
/// Path: /ws/notify?playerId={id}&access_token={token}
///
/// Delivers cross-feature push events: player notifications, game-event
/// eliminations/closures, guardian changes, territory captures, and vote tallies.
class NotificationHub extends HubClientBase {
  final _playerNotifications =
      StreamController<PlayerNotificationDto>.broadcast();
  final _gameEventEliminations =
      StreamController<GameEventEliminationDto>.broadcast();
  final _gameEventsClosed = StreamController<GameEventClosedDto>.broadcast();
  final _guardianChanges = StreamController<GuardianChangedDto>.broadcast();
  final _territoryCaptures = StreamController<TerritoryCaptureDto>.broadcast();
  final _voteTallyUpdates = StreamController<VoteTallyUpdatedDto>.broadcast();
  final _directMessagesUpdated =
      StreamController<DirectMessagesUpdatedDto>.broadcast();

  Stream<PlayerNotificationDto> get playerNotifications =>
      _playerNotifications.stream;
  Stream<GameEventEliminationDto> get gameEventEliminations =>
      _gameEventEliminations.stream;
  Stream<GameEventClosedDto> get gameEventsClosed => _gameEventsClosed.stream;
  Stream<GuardianChangedDto> get guardianChanges => _guardianChanges.stream;
  Stream<TerritoryCaptureDto> get territoryCaptures =>
      _territoryCaptures.stream;
  Stream<VoteTallyUpdatedDto> get voteTallyUpdates => _voteTallyUpdates.stream;
  Stream<DirectMessagesUpdatedDto> get directMessagesUpdated =>
      _directMessagesUpdated.stream;

  @override
  void registerHandlers(HubConnection connection) {
    connection.on('PlayerNotification', (args) {
      final raw = _firstArg(args);
      if (raw != null) {
        _playerNotifications.add(PlayerNotificationDto.fromJson(raw));
      }
    });

    connection.on('GameEventElimination', (args) {
      final raw = _firstArg(args);
      if (raw != null) {
        _gameEventEliminations.add(GameEventEliminationDto.fromJson(raw));
      }
    });

    connection.on('GameEventClosed', (args) {
      final raw = _firstArg(args);
      if (raw != null) {
        _gameEventsClosed.add(GameEventClosedDto.fromJson(raw));
      }
    });

    connection.on('GuardianChanged', (args) {
      final raw = _firstArg(args);
      if (raw != null) {
        _guardianChanges.add(GuardianChangedDto.fromJson(raw));
      }
    });

    connection.on('TerritoryCapture', (args) {
      final raw = _firstArg(args);
      if (raw != null) {
        _territoryCaptures.add(TerritoryCaptureDto.fromJson(raw));
      }
    });

    connection.on('VoteTallyUpdated', (args) {
      final raw = _firstArg(args);
      if (raw != null) {
        _voteTallyUpdates.add(VoteTallyUpdatedDto.fromJson(raw));
      }
    });

    connection.on('DirectMessagesUpdated', (args) {
      final raw = _firstArg(args);
      if (raw != null) {
        _directMessagesUpdated.add(DirectMessagesUpdatedDto.fromJson(raw));
      }
    });
  }

  // ── Group subscriptions ──────────────────────────────────────────────────

  Future<void> joinGameEvent(String gameEventId) =>
      invoke('JoinGameEvent', args: [gameEventId]);

  Future<void> joinGuardianWatch(String seasonId, int tierNumber) =>
      invoke('JoinGuardianWatch', args: [seasonId, tierNumber]);

  Future<void> joinTerritory(String seasonId, int tierNumber) =>
      invoke('JoinTerritory', args: [seasonId, tierNumber]);

  Future<void> joinTopic(String topic) => invoke('JoinTopic', args: [topic]);

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  Future<void> stop() async {
    await super.stop();
    await _playerNotifications.close();
    await _gameEventEliminations.close();
    await _gameEventsClosed.close();
    await _guardianChanges.close();
    await _territoryCaptures.close();
    await _voteTallyUpdates.close();
    await _directMessagesUpdated.close();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Map<String, dynamic>? _firstArg(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final raw = args[0];
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }
}
