import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/crypto/crypto_network.dart';
import '../../../../core/utils/crypto_address_validator.dart';
import '../../../../core/models/crypto/crypto_transaction_kind.dart';
import '../../../../game/providers/crypto_providers.dart';
import '../../../../core/models/crypto/crypto_history_item.dart';

class CryptoHoldingsCard extends ConsumerWidget {
  const CryptoHoldingsCard({
    super.key,
    required this.userId,
    required this.isOwnProfile,
  });

  final String userId;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(cryptoBalanceProvider(userId));
    final stakingAsync = ref.watch(cryptoStakingProvider(userId));
    final historyAsync = ref.watch(
      cryptoHistoryProvider(
          (playerId: userId, query: const CryptoHistoryQuery())),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF141A2B),
            const Color(0xFF10B981).withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.currency_bitcoin_rounded,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Crypto Holdings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isOwnProfile)
                TextButton(
                  onPressed: () {
                    context.push('/store/crypto-wallet');
                  },
                  child: const Text('Open wallet'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          historyAsync.maybeWhen(
            data: (history) {
              final network = _inferNetwork(history.items);
              if (network == null) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.currency_bitcoin_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${network.displayName} (${network.symbol})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          balanceAsync.when(
            data: (balance) => Row(
              children: [
                Expanded(
                  child: _HoldingMetric(
                    label: 'Available',
                    value: '${balance.units}',
                    subtitle: _symbolSubtitle(historyAsync.valueOrNull?.items,
                        fallback: balance.unitType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: stakingAsync.when(
                    data: (staking) => _HoldingMetric(
                      label: 'Staked',
                      value: '${staking.stakedUnits}',
                      subtitle: _symbolSubtitle(
                        historyAsync.valueOrNull?.items,
                        fallback: 'Locked units',
                      ),
                    ),
                    loading: () => const _HoldingMetricPlaceholder(),
                    error: (_, __) => const _HoldingMetric(
                      label: 'Staked',
                      value: '--',
                      subtitle: 'Unavailable',
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const _CryptoHoldingsLoadingState(),
            error: (error, _) => _HoldingsErrorState(
              message: error.toString(),
              isOwnProfile: isOwnProfile,
            ),
          ),
        ],
      ),
    );
  }

  String _symbolSubtitle(
    List<CryptoHistoryItem>? items, {
    required String fallback,
  }) {
    final network = _inferNetwork(items ?? const []);
    if (network == null) {
      return fallback;
    }
    return '${network.symbol} units';
  }

  CryptoNetwork? _inferNetwork(List<CryptoHistoryItem> items) {
    for (final item in items) {
      if (item.kind != CryptoTransactionKind.walletLink) {
        continue;
      }

      final address = item.receiptRef;
      if (address == null || address.isEmpty) {
        continue;
      }

      for (final network in CryptoNetwork.values) {
        if (CryptoAddressValidator.isValid(address, network)) {
          return network;
        }
      }
    }

    return null;
  }
}

class _HoldingMetric extends StatelessWidget {
  const _HoldingMetric({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldingMetricPlaceholder extends StatelessWidget {
  const _HoldingMetricPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _HoldingMetric(
      label: 'Staked',
      value: '...',
      subtitle: 'Loading',
    );
  }
}

class _CryptoHoldingsLoadingState extends StatelessWidget {
  const _CryptoHoldingsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 90,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _HoldingsErrorState extends StatelessWidget {
  const _HoldingsErrorState({
    required this.message,
    required this.isOwnProfile,
  });

  final String message;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isOwnProfile
                ? 'Your crypto balance is not available right now.'
                : 'This player\'s crypto balance is not available right now.',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
