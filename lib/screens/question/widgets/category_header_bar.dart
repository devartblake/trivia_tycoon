import 'package:flutter/material.dart';

/// Full-bleed category-colored header band (Trivia-Crack style): icon tile on
/// the left, bold uppercase category name, compact score/XP chip and a timer
/// chip on the right. Replaces the white AppBar + circular timer badge.
class CategoryHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;
  final int timeRemaining;
  final bool timerExpired;
  final bool isPaused;
  final int score;
  final int xp;

  const CategoryHeaderBar({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.timeRemaining,
    this.timerExpired = false,
    this.isPaused = false,
    this.score = 0,
    this.xp = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final tileColor =
        Color.alphaBlend(Colors.black.withValues(alpha: 0.22), color);
    final urgent = timerExpired || timeRemaining <= 10;

    return Container(
      color: color,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Row(
            children: [
              if (Navigator.of(context).canPop())
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              else
                const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Chip(
                background: Colors.white.withValues(alpha: 0.18),
                child: Text(
                  '$score pts · $xp XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Chip(
                background: urgent
                    ? Colors.red.shade600
                    : tileColor.withValues(alpha: 0.85),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      timerExpired
                          ? Icons.timer_off
                          : (isPaused ? Icons.pause : Icons.timer_outlined),
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timerExpired ? 'TIME UP' : '${timeRemaining}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final Color background;
  final Widget child;

  const _Chip({required this.background, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
  }
}
