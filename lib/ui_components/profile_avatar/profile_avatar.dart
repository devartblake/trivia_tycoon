import 'dart:ui';
import 'circular_alignment.dart';
import 'extensions.dart';
import 'profile_avatar_inherited.dart';
import 'profile_avatar_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

const _defaultAvatarSize = 50.0;
const _defaultAbbreviationFontSize = 15.0;

/// Modern Material Design 3 Profile Avatar widget with enhanced animations and styling
class ProfileAvatar extends StatefulWidget {
  // Core Properties
  final String? name; // Used for creating initials (Regex split by r'\s+\/')
  final double size; // Avatar size (width = height)
  final ImageProvider<Object>? image; // Avatar image source
  final Widget? child; // Child widget (mutually exclusive with image)

  // Styling & Decoration
  final BoxDecoration? decoration;
  final BoxDecoration? foregroundDecoration;
  final BoxShape avatarShape;
  final BoxFit fit;
  final EdgeInsetsGeometry? margin;
  final Alignment contentAlignment;

  // Status Indicator
  final Color? statusColor;
  final double statusSize;
  final Alignment statusAlignment;
  final bool animatedStatus; // Pulse animation for status

  // Badges
  final Widget? badge;
  final List<ProfileBadge>? badges;
  final Alignment badgeAlignment;
  final double badgeSize;
  final BoxDecoration? badgeDecoration;
  final bool badgeAnimated;

  // Text Styling
  final TextStyle? initialTextStyle;
  final bool autoTextSize; // Dynamic text size based on avatar size

  // Animation
  final bool animated; // Use AnimatedContainer
  final Duration duration;
  final Curve animationCurve;

  // Effects
  final bool useShimmer; // Shimmer loading effect
  final Color? glowColor; // Glow effect
  final double? glowRadius;
  final bool useGlassmorphism; // Modern glassmorphism effect
  final bool elevateOnHover; // Elevation on hover (web/desktop)

  // Accessibility
  final String? tooltip;
  final String? semanticLabel;

  // Error Handling
  final Widget? placeholder;
  final Widget? errorWidget;
  final VoidCallback? onImageError;

  // Additional Content
  final List<Widget> children;

  // Interaction
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableCropZoom;

  const ProfileAvatar({
    super.key,
    this.name,
    this.size = _defaultAvatarSize,
    this.image,
    this.child,
    this.decoration,
    this.foregroundDecoration,
    this.avatarShape = BoxShape.circle,
    this.fit = BoxFit.cover,
    this.margin,
    this.contentAlignment = Alignment.center,
    this.statusColor,
    this.statusSize = 12.0,
    this.statusAlignment = Alignment.bottomRight,
    this.animatedStatus = false,
    this.badge,
    this.badges,
    this.badgeAlignment = Alignment.bottomRight,
    this.badgeSize = 16.0,
    this.badgeDecoration,
    this.badgeAnimated = false,
    this.initialTextStyle,
    this.autoTextSize = true,
    this.animated = true,
    this.duration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.useShimmer = false,
    this.glowColor,
    this.glowRadius,
    this.useGlassmorphism = false,
    this.elevateOnHover = false,
    this.tooltip,
    this.semanticLabel,
    this.placeholder,
    this.errorWidget,
    this.onImageError,
    this.children = const <Widget>[],
    this.onTap,
    this.onLongPress,
    this.enableCropZoom = false,
  }) : assert(
  image == null || child == null,
  'Cannot provide both image and child',
  );

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _statusController;
  bool _isHovered = false;
  bool _hasImageError = false;

  @override
  void initState() {
    super.initState();
    _statusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.animatedStatus && widget.statusColor != null) {
      _statusController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animatedStatus && widget.statusColor != null) {
      if (!_statusController.isAnimating) {
        _statusController.repeat(reverse: true);
      }
    } else {
      _statusController.stop();
    }
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ProfileAvatarTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final dynamicTextSize =
        _defaultAbbreviationFontSize * (widget.size / _defaultAvatarSize);

    final textStyle = theme?.initialTextStyle?.merge(widget.initialTextStyle) ??
        widget.initialTextStyle ??
        TextStyle(
          fontSize: widget.autoTextSize ? dynamicTextSize : 18.0,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimaryContainer,
          letterSpacing: 0.5,
        );

    // Build content based on available data
    Widget content = _buildContent(textStyle, colorScheme);

    // Apply shimmer effect if enabled and no image
    if (widget.useShimmer && (widget.image == null || _hasImageError)) {
      content = Shimmer.fromColors(
        baseColor: colorScheme.surfaceContainerHighest,
        highlightColor: colorScheme.surface,
        child: content,
      );
    }

    // Default decoration with Material 3 styling
    final effectiveDecoration = widget.decoration ??
        theme?.decoration ??
        BoxDecoration(
          shape: widget.avatarShape,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );

    // Build the avatar container
    final avatarContainer = _buildAvatarContainer(
      content: content,
      decoration: effectiveDecoration,
      colorScheme: colorScheme,
    );

    // Wrap in gesture detector if tap callbacks are provided
    Widget avatarWidget = widget.onTap != null || widget.onLongPress != null
        ? Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        customBorder: widget.avatarShape == BoxShape.circle
            ? const CircleBorder()
            : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.size * 0.2),
        ),
        child: avatarContainer,
      ),
    )
        : avatarContainer;

    // Add hover effect for web/desktop
    if (widget.elevateOnHover) {
      avatarWidget = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: avatarWidget,
      );
    }

    // Wrap in Tooltip and Semantics for accessibility
    return Semantics(
      label: widget.semanticLabel ?? widget.name ?? 'Profile Avatar',
      image: widget.image != null,
      button: widget.onTap != null,
      child: Tooltip(
        message: widget.tooltip ?? widget.name ?? '',
        child: UnconstrainedBox(
          child: ProfileAvatarInherited(
            radius: widget.size / 2.0,
            child: avatarWidget,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(TextStyle textStyle, ColorScheme colorScheme) {
    // Handle image with error handling
    if (widget.image != null && !_hasImageError) {
      return Image(
        image: widget.image!,
        width: widget.size,
        height: widget.size,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _hasImageError = true);
              widget.onImageError?.call();
            }
          });
          return _buildFallbackContent(textStyle, colorScheme);
        },
      );
    }

    // Use child if provided
    if (widget.child != null) {
      return widget.child!;
    }

    // Use placeholder or fallback
    return _buildFallbackContent(textStyle, colorScheme);
  }

  Widget _buildFallbackContent(TextStyle textStyle, ColorScheme colorScheme) {
    if (widget.errorWidget != null && _hasImageError) {
      return widget.errorWidget!;
    }

    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    // Default: Show initials
    return Center(
      child: Text(
        widget.name.toAbbreviation(),
        style: textStyle,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAvatarContainer({
    required Widget content,
    required BoxDecoration decoration,
    required ColorScheme colorScheme,
  }) {
    final containerDecoration = decoration.copyWith(
      shape: widget.avatarShape,
      boxShadow: [
        ...?decoration.boxShadow,
        if (widget.glowColor != null && widget.glowRadius != null)
          BoxShadow(
            color: widget.glowColor!,
            blurRadius: widget.glowRadius!,
            spreadRadius: widget.glowRadius! * 0.5,
          ),
        if (_isHovered)
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
      ],
    );

    final container = Container(
      width: widget.size,
      height: widget.size,
      margin: widget.margin,
      clipBehavior: Clip.antiAlias,
      decoration: containerDecoration,
      foregroundDecoration: widget.foregroundDecoration,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Main content
          if (widget.animated)
            AnimatedContainer(
              duration: widget.duration,
              curve: widget.animationCurve,
              alignment: widget.contentAlignment,
              child: content,
            )
          else
            Align(
              alignment: widget.contentAlignment,
              child: content,
            ),

          // Glassmorphism overlay
          if (widget.useGlassmorphism)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: widget.avatarShape == BoxShape.circle
                    ? BorderRadius.circular(widget.size / 2)
                    : BorderRadius.circular(widget.size * 0.2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.surface.withValues(alpha: 0.1),
                          colorScheme.surface.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Status indicator with optional animation
          if (widget.statusColor != null) _buildStatusIndicator(),

          // Dynamic badge rendering
          if (widget.badges != null)
            ...widget.badges!.map((badge) => Align(
              alignment: badge.alignment,
              child: badge.badge,
            )),

          // Single badge
          if (widget.badge != null) _buildBadge(colorScheme),

          // Additional children widgets
          ...widget.children,
        ],
      ),
    );

    return container;
  }

  Widget _buildStatusIndicator() {
    final indicator = Container(
      width: widget.statusSize,
      height: widget.statusSize,
      decoration: BoxDecoration(
        color: widget.statusColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.statusColor!.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );

    return AlignCircular(
      alignment: widget.statusAlignment,
      child: widget.animatedStatus
          ? FadeTransition(
        opacity: _statusController,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0)
              .animate(_statusController),
          child: indicator,
        ),
      )
          : indicator,
    );
  }

  Widget _buildBadge(ColorScheme colorScheme) {
    final badge = Container(
      width: widget.badgeSize,
      height: widget.badgeSize,
      decoration: widget.badgeDecoration ??
          BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.error,
            border: Border.all(
              color: colorScheme.surface,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.2),
                blurRadius: 4,
              ),
            ],
          ),
      child: widget.badge,
    );

    return Align(
      alignment: widget.badgeAlignment,
      child: widget.badgeAnimated
          ? TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: badge,
      )
          : badge,
    );
  }
}

/// Badge configuration for ProfileAvatar
class ProfileBadge {
  final Widget badge;
  final Alignment alignment;
  final bool animated;

  const ProfileBadge({
    required this.badge,
    this.alignment = Alignment.bottomRight,
    this.animated = false,
  });
}