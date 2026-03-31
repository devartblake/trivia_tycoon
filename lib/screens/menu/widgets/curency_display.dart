import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Modern currency display with animated counters and glass morphism
class CurrencyDisplay extends StatelessWidget {
  final String ageGroup;
  final int coins;
  final int gems;
  final int currentEnergy;
  final int maxEnergy;
  final int currentLives;
  final int maxLives;
  final WidgetRef ref;
  final Function(int, int) showEnergyInfo;
  final Function(int, int) showLivesInfo;

  const CurrencyDisplay({
    super.key,
    required this.ageGroup,
    required this.coins,
    required this.gems,
    required this.currentEnergy,
    required this.maxEnergy,
    required this.currentLives,
    required this.maxLives,
    required this.ref,
    required this.showEnergyInfo,
    required this.showLivesInfo,
  });

  @override
  Widget build(BuildContext context) {
    final currencies = _getCurrencies(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: Row(
        children: currencies.asMap().entries.map((entry) {
          final index = entry.key;
          final currency = entry.value;
          final isLast = index == currencies.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _CurrencyItem(
                    name: currency['name'] as String,
                    value: currency['value'] as String,
                    icon: currency['icon'] as IconData,
                    color: currency['color'] as Color,
                    bgColor: currency['bgColor'] as Color,
                    onTap: currency['onTap'] as VoidCallback,
                    isLow: currency['isLow'] as bool,
                    animationDelay: index * 100,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 45,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF64748B).withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _getCurrencies(BuildContext context) {
    return [
      {
        'name': 'Coins',
        'value': _formatNumber(coins),
        'icon': Icons.monetization_on_rounded,
        'color': const Color(0xFFFFD700),
        'bgColor': const Color(0xFFFFF8DC),
        'onTap': () => _showCoinStore(context),
        'isLow': coins < 100,
      },
      {
        'name': 'Gems',
        'value': _formatNumber(gems),
        'icon': Icons.diamond_rounded,
        'color': const Color(0xFF6366F1),
        'bgColor': const Color(0xFFF0F0FF),
        'onTap': () => _showGemStore(context),
        'isLow': gems < 10,
      },
      {
        'name': 'Energy',
        'value': '$currentEnergy/$maxEnergy',
        'icon': Icons.flash_on_rounded,
        'color': const Color(0xFF10B981),
        'bgColor': const Color(0xFFF0FDF4),
        'onTap': () => showEnergyInfo(currentEnergy, maxEnergy),
        'isLow': currentEnergy < maxEnergy * 0.3,
      },
      {
        'name': 'Lives',
        'value': '$currentLives/$maxLives',
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFFEF4444),
        'bgColor': const Color(0xFFFEF2F2),
        'onTap': () => showLivesInfo(currentLives, maxLives),
        'isLow': currentLives < maxLives * 0.5,
      },
    ];
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  void _showCoinStore(BuildContext context) {
    context.push('/store');
  }

  void _showGemStore(BuildContext context) {
    context.push('/store');
  }
}

/// Individual currency item with modern design
class _CurrencyItem extends StatefulWidget {
  final String name;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isLow;
  final int animationDelay;

  const _CurrencyItem({
    required this.name,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    required this.isLow,
    required this.animationDelay,
  });

  @override
  State<_CurrencyItem> createState() => _CurrencyItemState();
}

class _CurrencyItemState extends State<_CurrencyItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: 10),
            _buildValue(),
            const SizedBox(height: 3),
            _buildLabel(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: widget.color,
            size: 24,
          ),
        ),
        if (widget.isLow)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.priority_high_rounded,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildValue() {
    return Text(
      widget.value,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: widget.isLow ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildLabel() {
    return Text(
      widget.name,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF64748B),
        letterSpacing: 0.2,
      ),
    );
  }
}
