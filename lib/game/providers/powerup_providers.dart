import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dto/powerup_dto.dart';
import '../../core/networking/synaptix_api_client.dart';
import 'core_providers.dart';

/// Loads and mutates a player's server-side powerup inventory
/// (`/powerups/state`, `/powerups/use`).
class PowerupInventoryController
    extends StateNotifier<AsyncValue<PowerupStateDto>> {
  final SynaptixApiClient _api;
  final String playerId;

  PowerupInventoryController(this._api, this.playerId)
      : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _api.getPowerupState(playerId: playerId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Consumes one powerup of [type] within game [eventId]. On a successful
  /// `Used` result the local inventory is refreshed. Returns the result, or
  /// null if the request failed (network/server error).
  Future<UsePowerupResultDto?> use({
    required String eventId,
    required PowerupType type,
  }) async {
    try {
      final res = await _api.usePowerup(
        eventId: eventId,
        playerId: playerId,
        type: type,
      );
      if (res.used) await load();
      return res;
    } catch (_) {
      return null;
    }
  }
}

/// Per-player powerup inventory. Auto-loads on first watch.
final powerupInventoryProvider = StateNotifierProvider.autoDispose
    .family<PowerupInventoryController, AsyncValue<PowerupStateDto>, String>(
        (ref, playerId) {
  final api = ref.watch(synaptixApiClientProvider);
  return PowerupInventoryController(api, playerId)..load();
});
