import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/controllers/power_up_controller.dart';
import '../../../core/services/settings/app_settings.dart';
import '../../../game/models/power_up.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../../game/models/store_item_model.dart';

class StoreItemCard extends ConsumerStatefulWidget {
  final String name;
  final String description;
  final String iconPath;
  final String price;
  final StoreItemModel item;
  final VoidCallback onBuy;

  const StoreItemCard({
    super.key,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.price,
    required this.item,
    required this.onBuy,
  });

  @override
  ConsumerState<StoreItemCard> createState() => _StoreItemCardState();
}

class _StoreItemCardState extends ConsumerState<StoreItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyManager = ref.watch(currencyManagerProvider);
    final isDiamond = widget.item.currency == 'diamonds';
    final isExternalCheckout =
        widget.item.requiresExternalCheckout ||
        widget.item.currency.toLowerCase() == 'usd';
    final balance =
        isExternalCheckout ? 0 : currencyManager.getBalance(widget.item.currencyType);
    final equipped = ref.watch(equippedPowerUpProvider);

    final isPowerUp = widget.item.category.toLowerCase() == 'power-up';
    final tag = widget.item.type?.toUpperCase() ?? '';
    final glowColor = _getGlowColor(widget.item.type);
    final canAfford = isExternalCheckout || balance >= widget.item.price;

    return FutureBuilder(
      future: AppSettings.isInInventory(widget.item.id),
      builder: (context, snapshot) {
        final isOwned = widget.item.owned || (snapshot.data ?? false);
        final isEquipped = equipped?.id == widget.item.id;

        return GestureDetector(
          onTapDown: (_) {
            _pulseController.forward();
          },
          onTapUp: (_) {
            _pulseController.reverse();
          },
          onTapCancel: () {
            _pulseController.reverse();
          },
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isEquipped
                          ? glowColor
                          : isPowerUp
                          ? glowColor.withValues(alpha: 0.3)
                          : const Color(0xFF64748B).withValues(alpha: 0.1),
                      width: isEquipped ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isEquipped
                            ? glowColor.withValues(alpha: 0.3)
                            : isPowerUp
                            ? glowColor.withValues(alpha: 0.1)
                            : const Color(0xFF64748B).withValues(alpha: 0.08),
                        blurRadius: isEquipped ? 15 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with badge and status
                        SizedBox(
                          height: 24,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status indicators
                              if (isOwned)
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isEquipped
                                          ? glowColor
                                          : const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isEquipped ? Icons.star : Icons.check,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isEquipped ? 'EQUIPPED' : 'OWNED',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              // Type badge for power-ups
                              if (isPowerUp && tag.isNotEmpty)
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: glowColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: glowColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        color: glowColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Item Image with glow effect
                        Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: isPowerUp
                                ? BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: glowColor.withOpacity(
                                      isEquipped ? 0.6 : 0.3),
                                  blurRadius: isEquipped ? 15 : 8,
                                  spreadRadius: isEquipped ? 3 : 1,
                                ),
                              ],
                            )
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isPowerUp
                                    ? glowColor.withValues(alpha: 0.1)
                                    : const Color(0xFFF8FAFF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isPowerUp
                                      ? glowColor.withValues(alpha: 0.3)
                                      : const Color(0xFF64748B).withValues(alpha: 0.1),
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  widget.iconPath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      _getDefaultIcon(widget.item.category),
                                      color: isPowerUp
                                          ? glowColor
                                          : const Color(0xFF64748B),
                                      size: 24,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Item Info - Made more compact
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // Price and Action Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Price display
                            Row(
                              children: [
                                Icon(
                                  isExternalCheckout
                                      ? Icons.open_in_new
                                      : isDiamond
                                          ? Icons.diamond
                                          : Icons.monetization_on,
                                  color: isExternalCheckout
                                      ? const Color(0xFF0F766E)
                                      : isDiamond
                                          ? const Color(0xFF6366F1)
                                          : const Color(0xFFF59E0B),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.item.displayPriceLabel ?? widget.price,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isExternalCheckout
                                        ? const Color(0xFF0F766E)
                                        : isDiamond
                                            ? const Color(0xFF6366F1)
                                            : const Color(0xFFF59E0B),
                                  ),
                                ),
                                const Spacer(),
                                if (!canAfford && !isOwned)
                                  Icon(
                                    Icons.warning,
                                    color: const Color(0xFFEF4444),
                                    size: 14,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Action Button
                            SizedBox(
                              width: double.infinity,
                              height: 32,
                              child: _buildActionButton(
                                isOwned: isOwned,
                                isEquipped: isEquipped,
                                canAfford: canAfford,
                                isPowerUp: isPowerUp,
                                glowColor: glowColor,
                                isExternalCheckout: isExternalCheckout,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required bool isOwned,
    required bool isEquipped,
    required bool canAfford,
    required bool isPowerUp,
    required Color glowColor,
    required bool isExternalCheckout,
  }) {
    if (isOwned) {
      if (isPowerUp) {
        return ElevatedButton(
          onPressed: isEquipped ? null : _handleEquip,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEquipped ? Colors.grey.shade300 : glowColor,
            foregroundColor: isEquipped ? Colors.grey.shade600 : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
            minimumSize: Size.zero,
          ),
          child: Text(
            isEquipped ? 'Equipped' : 'Equip',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 14,
              ),
              SizedBox(width: 6),
              Text(
                'Owned',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }
    }

    return ElevatedButton(
      onPressed: canAfford ? _handlePurchase : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford
            ? (isExternalCheckout
                ? const Color(0xFF0F766E)
                : (isPowerUp ? glowColor : const Color(0xFF6366F1)))
            : Colors.grey.shade300,
        foregroundColor: canAfford ? Colors.white : Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
        minimumSize: Size.zero,
      ),
      child: Text(
        isExternalCheckout
            ? 'Checkout'
            : canAfford
                ? 'Buy'
                : 'Need More',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _handlePurchase() async {
    HapticFeedback.mediumImpact();

    if (widget.item.requiresExternalCheckout ||
        widget.item.currency.toLowerCase() == 'usd') {
      widget.onBuy();
      return;
    }

    final currencyManager = ref.read(currencyManagerProvider);
    final balance = currencyManager.getBalance(widget.item.currencyType);
    final notifier = currencyManager.getNotifier(widget.item.currencyType);

    if (balance >= widget.item.price) {
      try {
        await notifier.deduct(widget.item.price);
        await AppSettings.addToInventory(widget.item.id);

        if (mounted) {
          widget.onBuy();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Successfully purchased ${widget.name}!'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Purchase failed. Please try again.'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 12),
                Text('Not enough ${widget.item.currency}!'),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _handleEquip() async {
    HapticFeedback.lightImpact();

    try {
      final powerUpController = ref.read(equippedPowerUpProvider.notifier);

      // Convert your item to a PowerUp model
      final powerUp = PowerUp(
        id: widget.item.id,
        name: widget.item.name,
        description: widget.item.description,
        type: widget.item.type ?? 'boost',
        duration: 300, // 5 minutes default, adjust as needed
        iconPath: widget.item.iconPath,
        price: widget.item.price,
        currency: widget.item.currency,
      );

      await powerUpController.activate(powerUp);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.star, color: Colors.white),
                const SizedBox(width: 12),
                Text('${widget.name} equipped!'),
              ],
            ),
            backgroundColor: _getGlowColor(widget.item.type),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Failed to equip item.'),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Color _getGlowColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'xp':
        return const Color(0xFFF59E0B);
      case 'shield':
        return const Color(0xFF6366F1);
      case 'hint':
        return const Color(0xFF10B981);
      case 'eliminate':
        return const Color(0xFFEF4444);
      case 'boost':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFFEC4899);
    }
  }

  IconData _getDefaultIcon(String category) {
    switch (category.toLowerCase()) {
      case 'power-up':
        return Icons.auto_fix_high;
      case 'avatar':
        return Icons.person;
      case 'theme':
        return Icons.palette;
      case 'currency':
        return Icons.monetization_on;
      default:
        return Icons.shopping_bag;
    }
  }
}
