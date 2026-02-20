import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../game/models/drawer_menu_data.dart';
import '../../../game/utils/drawer_animations.dart';

/// Gradient-styled menu item with animation
class GradientMenuItemWidget extends StatelessWidget {
  final GradientMenuItem item;
  final bool isSelected;
  final AnimationController animationController;

  const GradientMenuItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return DrawerAnimations.slideFromLeft(
      animation: animationController,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? item.gradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: item.gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: const Color(0xFF64748B).withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : const Color(0xFF64748B).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : item.gradient.colors.first.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: isSelected ? Colors.white : item.gradient.colors.first,
              size: 20,
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            color: isSelected
                ? Colors.white.withValues(alpha: 0.8)
                : const Color(0xFF64748B).withValues(alpha: 0.5),
            size: 16,
          ),
          onTap: () {
            Navigator.pop(context);
            if (item.route == '/') {
              context.go('/');
            } else {
              context.push(item.route);
            }
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ),
    );
  }
}
