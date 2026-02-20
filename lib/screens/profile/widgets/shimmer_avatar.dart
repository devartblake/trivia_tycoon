import 'dart:io';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';

enum AvatarStatus { online, offline, away, busy }
enum AvatarBadgeType { none, level, notification, premium }

class ShimmerAvatar extends StatefulWidget {
  final String? avatarPath;
  final AvatarStatus status;
  final bool isLoading;
  final double radius;
  final AvatarBadgeType badgeType;
  final String? badgeText;
  final int? notificationCount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showStatusIndicator;
  final bool enableHoverEffect;
  final Color? borderColor;
  final double borderWidth;
  final BoxShadow? customShadow;
  final String? heroTag;
  final Widget? overlayWidget;
  final double? overlayOpacity;

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
  });

  @override
  State<ShimmerAvatar> createState() => _ShimmerAvatarState();
}

class _ShimmerAvatarState extends State<ShimmerAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case AvatarStatus.online:
        return Colors.green;
      case AvatarStatus.offline:
        return Colors.grey;
      case AvatarStatus.away:
        return Colors.amber;
      case AvatarStatus.busy:
        return Colors.red;
    }
  }

  Widget _buildAvatar() {
    if (widget.avatarPath != null && widget.avatarPath!.isNotEmpty) {
      if (widget.avatarPath!.startsWith('assets/')) {
        return Image.asset(
          widget.avatarPath!,
          fit: BoxFit.cover,
          width: widget.radius * 2,
          height: widget.radius * 2,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
        );
      } else if (widget.avatarPath!.startsWith('http')) {
        return Image.network(
          widget.avatarPath!,
          fit: BoxFit.cover,
          width: widget.radius * 2,
          height: widget.radius * 2,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildShimmerEffect();
          },
        );
      } else {
        return Image.file(
          File(widget.avatarPath!),
          fit: BoxFit.cover,
          width: widget.radius * 2,
          height: widget.radius * 2,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
        );
      }
    }
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person,
        size: widget.radius * 0.8,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.white,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: widget.radius * 2,
        height: widget.radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (!widget.showStatusIndicator) return const SizedBox.shrink();

    return Positioned(
      bottom: widget.radius * 0.05,
      right: widget.radius * 0.05,
      child: Container(
        width: widget.radius * 0.35,
        height: widget.radius * 0.35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getStatusColor(),
          border: Border.all(
            color: Colors.white,
            width: widget.radius * 0.08,
          ),
          boxShadow: [
            BoxShadow(
              color: _getStatusColor().withValues(alpha: 0.5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: widget.status == AvatarStatus.away
            ? Icon(
          Icons.schedule,
          size: widget.radius * 0.15,
          color: Colors.white,
        )
            : widget.status == AvatarStatus.busy
            ? Icon(
          Icons.do_not_disturb,
          size: widget.radius * 0.15,
          color: Colors.white,
        )
            : null,
      ),
    );
  }

  Widget _buildBadge() {
    if (widget.badgeType == AvatarBadgeType.none) return const SizedBox.shrink();

    Widget badgeContent;
    Color badgeColor;

    switch (widget.badgeType) {
      case AvatarBadgeType.level:
        badgeContent = Text(
          widget.badgeText ?? 'LV',
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.radius * 0.2,
            fontWeight: FontWeight.bold,
          ),
        );
        badgeColor = Colors.blue;
        break;
      case AvatarBadgeType.notification:
        badgeContent = Text(
          '${widget.notificationCount ?? 0}',
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.radius * 0.18,
            fontWeight: FontWeight.bold,
          ),
        );
        badgeColor = Colors.red;
        break;
      case AvatarBadgeType.premium:
        badgeContent = Icon(
          Icons.star,
          size: widget.radius * 0.25,
          color: Colors.white,
        );
        badgeColor = Colors.amber;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(widget.radius * 0.08),
        decoration: BoxDecoration(
          color: badgeColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          minWidth: widget.radius * 0.4,
          minHeight: widget.radius * 0.4,
        ),
        child: Center(child: badgeContent),
      ),
    );
  }

  Widget _buildOverlay() {
    if (widget.overlayWidget == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: widget.overlayOpacity ?? 0.3),
        ),
        child: Center(child: widget.overlayWidget),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarContent = Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: widget.borderColor != null
            ? Border.all(
          color: widget.borderColor!,
          width: widget.borderWidth,
        )
            : null,
        boxShadow: widget.customShadow != null
            ? [widget.customShadow!]
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: widget.isLoading ? _buildShimmerEffect() : _buildAvatar(),
      ),
    );

    // Apply scale animation only when pressed
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

    // Wrap in Hero if heroTag provided
    if (widget.heroTag != null) {
      avatarContent = Hero(
        tag: widget.heroTag!,
        child: avatarContent,
      );
    }

    // Always wrap in GestureDetector for consistent widget tree
    Widget gestureWrapper = GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: widget.enableHoverEffect
          ? (_) {
        if (mounted) {
          setState(() => _isPressed = true);
          _animationController.forward();
        }
      }
          : null,
      onTapUp: widget.enableHoverEffect
          ? (_) {
        if (mounted) {
          setState(() => _isPressed = false);
          _animationController.reverse();
        }
      }
          : null,
      onTapCancel: widget.enableHoverEffect
          ? () {
        if (mounted) {
          setState(() => _isPressed = false);
          _animationController.reverse();
        }
      }
          : null,
      child: avatarContent,
    );

    // Build the complete avatar with overlays
    return SizedBox(
      width: widget.radius * 2.5,
      height: widget.radius * 2.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          gestureWrapper,
          _buildOverlay(),
          _buildStatusIndicator(),
          _buildBadge(),
        ],
      ),
    );
  }
}
