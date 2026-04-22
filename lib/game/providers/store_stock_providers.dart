import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/store/store_stock_ui_model.dart';
import 'riverpod_providers.dart';

/// Shared clock — one tick per second used by all countdown widgets.
/// Cards derive remaining duration from this rather than each running their own Timer.
final stockCountdownProvider = StreamProvider<DateTime>((ref) async* {
  while (true) {
    yield DateTime.now().toUtc();
    await Future.delayed(const Duration(seconds: 1));
  }
});

/// Player-scoped catalog with stock state.
/// Calls GET /store/catalog/{playerId}; falls back to generic catalog on error.
final playerStoreCatalogProvider =
    FutureProvider.family<List<PlayerStoreItem>, String>(
        (ref, playerId) async {
  final service = ref.watch(storeServiceProvider);
  return service.fetchPlayerCatalog(playerId);
});

/// Convenience provider that auto-resolves the current player id and fetches the catalog.
/// Returns an empty list if the player id is unavailable.
final currentPlayerStoreCatalogProvider =
    FutureProvider<List<PlayerStoreItem>>((ref) async {
  final playerId = await ref.watch(currentUserIdProvider.future);
  return ref.watch(playerStoreCatalogProvider(playerId).future);
});
