import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/animations/animation_manager.dart';
import '../../../game/models/drawer_menu_data.dart';

/// Simple-styled menu item with animation
class SimpleMenuItemWidget extends StatelessWidget {
  final SimpleMenuItem item;
  final AnimationController animationController;

  const SimpleMenuItemWidget({
    super.key,
    required this.item,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationManager.slideFromLeft(
      animation: animationController,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF64748B).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              color: item.color,
              size: 18,
            ),
          ),
          title: Text(
            item.title,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color(0xFF9CA3AF),
            size: 12,
          ),
          onTap: () {
            Navigator.pop(context);
            context.push(item.route);
          },
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        ),
      ),
    );
  }
}
