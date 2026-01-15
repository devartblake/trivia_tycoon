import 'dart:io';
import 'package:flutter/material.dart';

class AvatarImageCard extends StatefulWidget {
  final String imagePath;
  final VoidCallback onTap;

  const AvatarImageCard({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<AvatarImageCard> createState() => _AvatarImageCardState();
}

class _AvatarImageCardState extends State<AvatarImageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isPressed
                  ? [
                const Color(0xFF6366F1).withOpacity(0.3),
                const Color(0xFF8B5CF6).withOpacity(0.2),
              ]
                  : [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed
                  ? const Color(0xFF6366F1).withOpacity(0.5)
                  : Colors.white.withOpacity(0.12),
              width: 2,
            ),
            boxShadow: _isPressed
                ? [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image(
                  image: widget.imagePath.startsWith('assets/')
                      ? AssetImage(widget.imagePath) as ImageProvider
                      : FileImage(File(widget.imagePath)),
                  fit: BoxFit.cover,
                ),
                if (_isPressed)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.2),
                          const Color(0xFF8B5CF6).withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}