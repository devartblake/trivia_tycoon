import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/dto/economy_dto.dart';
import '../../../game/analytics/providers/analytics_providers.dart';
import '../../../game/providers/core_providers.dart';
import '../../../game/providers/profile_providers.dart';

/// Bottom sheet that fetches and displays a revive quote before purchase.
///
/// Usage:
/// ```dart
/// final revived = await ReviveSheet.show(context, almostWin: score > threshold);
/// if (revived) { /* continue the match */ }
/// ```
class ReviveSheet extends ConsumerStatefulWidget {
  final bool almostWin;

  const ReviveSheet._({required this.almostWin});

  static Future<bool> show(
    BuildContext context, {
    required bool almostWin,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: ReviveSheet._(almostWin: almostWin),
      ),
    ).then((v) => v ?? false);
  }

  @override
  ConsumerState<ReviveSheet> createState() => _ReviveSheetState();
}

class _ReviveSheetState extends ConsumerState<ReviveSheet> {
  ReviveQuoteDto? _quote;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    try {
      final playerId = await ref.read(currentUserIdProvider.future);
      final api = ref.read(synaptixApiClientProvider);
      final q = await api.getReviveQuote(
        playerId: playerId,
        almostWin: widget.almostWin,
      );
      ref.read(analyticsServiceProvider).logEvent('revive_quote_loaded', {
        'playerId': playerId,
        'finalCost': q.finalCost,
        'almostWin': widget.almostWin,
        'discounted': q.hasDiscount,
      });
      if (mounted) setState(() { _quote = q; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (_loading)
            const _ReviveSheetSkeleton()
          else if (_error != null)
            _ReviveSheetError(onRetry: _loadQuote)
          else
            _ReviveSheetContent(
              quote: _quote!,
              almostWin: widget.almostWin,
              onDecline: () => Navigator.pop(context, false),
              onRevive: () => Navigator.pop(context, true),
            ),
        ],
      ),
    );
  }
}

class _ReviveSheetContent extends StatelessWidget {
  final ReviveQuoteDto quote;
  final bool almostWin;
  final VoidCallback onDecline;
  final VoidCallback onRevive;

  const _ReviveSheetContent({
    required this.quote,
    required this.almostWin,
    required this.onDecline,
    required this.onRevive,
  });

  String _currencyIcon() =>
      quote.costCurrency == 'gems' ? '💎' : '🪙';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Continue Playing?',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (quote.almostWinApplied)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.5)),
            ),
            child: const Text(
              'Almost-win discount applied!',
              style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
        const SizedBox(height: 12),
        // Cost display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (quote.hasDiscount) ...[
              Text(
                '${_currencyIcon()} ${quote.baseCost}',
                style: TextStyle(
                  fontSize: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              '${_currencyIcon()} ${quote.finalCost}',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          quote.costCurrency == 'gems' ? 'gems' : 'coins',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 28),
        // Action row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDecline,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('No thanks'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onRevive,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Revive!',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviveSheetSkeleton extends StatelessWidget {
  const _ReviveSheetSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: CircularProgressIndicator(),
    );
  }
}

class _ReviveSheetError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ReviveSheetError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        const Text('Could not load revive offer'),
        const SizedBox(height: 16),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
