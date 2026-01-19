import 'package:flutter/material.dart';
import 'models/avatar_enums.dart';
import 'widgets/avatar_content.dart';
import 'widgets/avatar_badge.dart';
import 'widgets/status_indicator.dart';
import 'widgets/avatar_overlay.dart';
import 'utils/avatar_helpers.dart';

/// Modern, modular avatar widget with shimmer loading effect
///
/// Features:
/// - Gradient borders and shadows
/// - Status indicators with animations
/// - Badge support (level, notification, premium)
/// - Custom overlays
/// - Tap and long-press callbacks
/// - Hero animations
/// - Loading states with shimmer
class ShimmerAvatar extends StatefulWidget {
  /// Path to avatar image (assets, network, or file)
  final String? avatarPath;

  /// Online status of the user
  final AvatarStatus status;

  /// Whether to show loading shimmer effect
  final bool isLoading;

  /// Radius of the avatar
  final double radius;

  /// Type of badge to display
  final AvatarBadgeType badgeType;

  /// Text to display in badge (for level badge)
  final String? badgeText;

  /// Notification count (for notification badge)
  final int? notificationCount;

  /// Callback when avatar is tapped
  final VoidCallback? onTap;

  /// Callback when avatar is long-pressed
  final VoidCallback? onLongPress;

  /// Whether to show status indicator
  final bool showStatusIndicator;

  /// Whether to enable hover/press effect
  final bool enableHoverEffect;

  /// Custom border color (overrides gradient)
  final Color? borderColor;

  /// Border width
  final double borderWidth;

  /// Custom shadow (overrides default)
  final BoxShadow? customShadow;

  /// Hero tag for hero animations
  final String? heroTag;

  /// Custom overlay widget
  final Widget? overlayWidget;

  /// Opacity of overlay
  final double? overlayOpacity;

  /// Whether to use gradient border (default: true)
  final bool useGradientBorder;

  /// Whether to use glow effect (default: true)
  final bool useGlowEffect;

  const ShimmerAvatar({
    super.key,
    this.avatarPath,
    this.status = AvatarStatus.online,
    this.isLoading = false,
    this.radius = 36,
    this.badgeType = AvatarBadgeType.none,
    this.badgeText,
    this.notificationCount,
    this.onTap,
    this.onLongPress,
    this.showStatusIndicator = true,
    this.enableHoverEffect = true,
    this.borderColor,
    this.borderWidth = 2.0,
    this.customShadow,
    this.heroTag,
    this.overlayWidget,
    this.overlayOpacity = 0.3,
    this.useGradientBorder = true,
    this.useGlowEffect = true,
  });

  @override
  State<ShimmerAvatar> createState() => _ShimmerAvatarState();
}

class _ShimmerAvatarState extends State<ShimmerAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.radius * 2.5,
      height: widget.radius * 2.5,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Main avatar with border and shadows
          _buildAvatarContainer(),

          // Overlay (if provided)
          AvatarOverlay(
            overlayWidget: widget.overlayWidget,
            opacity: widget.overlayOpacity ?? 0.3,
          ),

          // Status indicator
          if (widget.showStatusIndicator)
            Positioned(
              bottom: widget.radius * 0.05,
              right: widget.radius * 0.05,
              child: AvatarStatusIndicator(
                status: widget.status,
                avatarRadius: widget.radius,
                animated: true,
              ),
            ),

          // Badge
          if (widget.badgeType != AvatarBadgeType.none)
            Positioned(
              top: 0,
              right: 0,
              child: AvatarBadge(
                badgeType: widget.badgeType,
                avatarRadius: widget.radius,
                badgeText: widget.badgeText,
                notificationCount: widget.notificationCount,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContainer() {
    // Determine shadow
    final List<BoxShadow> shadows = widget.customShadow != null
        ? [widget.customShadow!]
        : [
      ...AvatarHelpers.getModernShadow(),
      if (widget.useGlowEffect) ...AvatarHelpers.getGradientGlow(),
    ];

    // Determine border decoration
    final BoxDecoration borderDecoration = widget.borderColor != null
        ? BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: widget.borderColor!,
        width: widget.borderWidth,
      ),
      boxShadow: shadows,
    )
        : widget.useGradientBorder
        ? BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: AvatarHelpers.getGradientBorderColors(),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: shadows,
    )
        : BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: widget.borderWidth,
      ),
      boxShadow: shadows,
    );

    Widget avatarContent = Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      padding: EdgeInsets.all(widget.borderWidth),
      decoration: borderDecoration,
      child: ClipOval(
        child: AvatarContent(
          avatarPath: widget.avatarPath,
          radius: widget.radius,
          isLoading: widget.isLoading,
        ),
      ),
    );

    // Apply scale animation when pressed
    if (widget.enableHoverEffect && _isPressed) {
      avatarContent = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: avatarContent,
      );
    }

    // Wrap in Hero if tag provided
    if (widget.heroTag != null) {
      avatarContent = Hero(
        tag: widget.heroTag!,
        child: avatarContent,
      );
    }

    // Wrap with gesture detector
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: widget.enableHoverEffect
          ? (_) {
        if (mounted) {
          setState(() => _isPressed = true);
          _scaleController.forward();
        }
      }
          : null,
      onTapUp: widget.enableHoverEffect
          ? (_) {
        if (mounted) {
          setState(() => _isPressed = false);
          _scaleController.reverse();
        }
      }
          : null,
      onTapCancel: widget.enableHoverEffect
          ? () {
        if (mounted) {
          setState(() => _isPressed = false);
          _scaleController.reverse();
        }
      }
          : null,
      child: avatarContent,
    );
  }
}