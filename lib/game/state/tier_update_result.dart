import '../models/tier_model.dart';

class TierUpdateResult {
  final int oldTierId;
  final int newTierId;
  final bool tierChanged;
  final List<TierModel> newUnlocks;

  const TierUpdateResult({
    required this.oldTierId,
    required this.newTierId,
    required this.tierChanged,
    required this.newUnlocks,
  });

  bool get hasNewUnlocks => newUnlocks.isNotEmpty;
  TierModel? get newTier => tierChanged ? null : null; // You'd get this from manager
}