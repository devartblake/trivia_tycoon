import 'circular_alignment.dart';
import 'extensions.dart';
import 'profile_avatar_inherited.dart';
import 'profile_avatar_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

const _defaultAvatarSize = 50.0;
const _defaultAbbreviationFontSize = 15.0;

// Profile Avatar widget.
class ProfileAvatar extends StatelessWidget {
  // Properties
  final String? name; /// Used for creating initials. (Regex split by r'\s+\/')
  final double size; /// Avatar size (width = height).  
  final Widget? badge;
  final List<ProfileBadge>? badges;
  final ImageProvider<Object>? image; /// Avatar image source exclusively with [child].  
  final EdgeInsetsGeometry? margin; /// Avatar margin. 
  final TextStyle? initialTextStyle; /// Initials text style. 
  final Color? statusColor; /// Status color. 
  final double statusSize; /// Status size.
  final BoxFit fit;
  final Alignment statusAlignment; /// Status angle.
  final Alignment badgeAlignment; // Position of the badge.
  final double badgeSize; // Size of the badge.
  final BoxDecoration? badgeDecoration; // Style of the badge.
  final Alignment contentAlignment;
  final BoxDecoration decoration; /// Avatar decoration. 
  final BoxDecoration? foregroundDecoration; /// Avatar foreground decoration. 
  final Widget? child; /// Child widget exclusively with [image]. 
  final List<Widget> children; /// Children widgets. 
  final bool animated; /// Use AnimatedContainer.  
  final Duration duration;/// AnimatedContainer duration. 
  final bool autoTextSize; /// Whether the [name] text should dynamically changes according to [size].
  final Widget? placeholder; // Placeholder content (NEW)
  final String? tooltip; // Tooltip for accessibility (NEW)
  final String? semanticLabel; // Semantic label for screen readers (NEW)
  final Widget? errorWidget;
  final bool badgeAnimated;
  final BoxShape avatarShape;
  final Color? glowColor;
  final double? glowRadius;
  final bool enableCropZoom;
  final Curve animationCurve;
  final bool useShimmer;

  const ProfileAvatar({
    super.key,
    this.name,
    this.size = _defaultAvatarSize,
    this.image,
    this.badge,
    this.badges,
    this.initialTextStyle,
    this.statusColor,
    this.statusSize = 12.0,
    this.fit = BoxFit.cover,
    this.statusAlignment = Alignment.bottomRight,
    this.badgeAlignment = Alignment.bottomRight, // Default alignment
    this.badgeSize = 16.0, // Default size
    this.badgeDecoration, // Badge decoration
    this.decoration = const BoxDecoration(
      shape: BoxShape.circle,
      color: Color.fromRGBO(0, 0, 0, 1),
    ),
    this.foregroundDecoration,
    this.child,
    this.children = const <Widget>[],
    this.animated = false,
    this.duration = const Duration(milliseconds: 300),
    this.autoTextSize = false, 
    this.margin,
    this.contentAlignment = Alignment.center, // Default to center
    this.placeholder, 
    this.tooltip,
    this.semanticLabel,
    this.errorWidget,
    this.badgeAnimated = false,
    this.avatarShape = BoxShape.circle,
    this.glowColor,
    this.glowRadius,
    this.enableCropZoom = false,
    this.animationCurve = Curves.linear,
    this.useShimmer = false,
  });

@override
  Widget build(BuildContext context) {
    final theme = ProfileAvatarTheme.of(context);
    final dynamicTextSize =
        _defaultAbbreviationFontSize * (size / _defaultAvatarSize);

    final textStyle = theme?.initialTextStyle?.merge(initialTextStyle) ?? 
      const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w500,
      );

    final effectiveDecoration = theme?.decoration ?? decoration;

    // Placeholder or fallback for missing image
    final content = image == null
        ? Image(
            image: image!,
            width: size,
            height: size,
            fit: fit,
            errorBuilder: (_, __, ___) =>
                errorWidget ?? placeholder ?? Text(name.toAbbreviation()),
          )

        : placeholder ??
            Text(
              name.toAbbreviation(),
              style: autoTextSize
                  ? textStyle.copyWith(fontSize: dynamicTextSize)
                  : textStyle,
            );

    // Apply shimmer effect if enabled
    final avatarContent = useShimmer && image == null
      ? Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: content,
        )
      : content;

    // Wrap avatar in Tooltip and Semantics for accessibility
    final avatarWidget = Semantics(
      label: semanticLabel ?? name,
      child: Tooltip(
        message: tooltip ?? name ?? "Profile Avatar",
        child: Container(
          width: size,
          height: size,
          margin: margin,
          decoration: decoration.copyWith(
            shape: avatarShape,
            boxShadow: glowColor != null && glowRadius != null
                ? [
                    BoxShadow(
                      color: glowColor!,
                      blurRadius: glowRadius!,
                      spreadRadius: 1.0,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background with optional animation
              if (animated)
                AnimatedContainer(
                  duration: duration,
                  alignment: contentAlignment, // New content alignment
                  curve: animationCurve,
                  // clipBehavior: Clip.antiAlias,
                  decoration: effectiveDecoration,
                  foregroundDecoration: foregroundDecoration,
                  child: avatarContent,
                )
              else
                Container(
                  alignment: contentAlignment, // New content alignment
                  clipBehavior: Clip.antiAlias,
                  decoration: effectiveDecoration,
                  foregroundDecoration: foregroundDecoration,
                  child: avatarContent,
                ),

              // Status indicator
              if (statusColor != null)
                AlignCircular(
                  alignment: statusAlignment,
                  child: Container(
                    width: statusSize,
                    height: statusSize,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color.fromRGBO(255, 255, 255, 1),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),

              // Dynamic Badge Rendering
              if (badges != null)
                ...badges!.map((badge) => Align(
                      alignment: badge.alignment,
                      child: badge.badge,
                    )),

              if (badge != null)
                Align(
                  alignment: badgeAlignment,
                  child: Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: badgeDecoration ??
                        const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                    child: badge,
                  ),
                ),

              // Additional Children Widgets
              for (final widget in children) widget,
            ],
          ),
        ),
      ),
    );

    // Wrap in UnconstrainedBox for proper layout
    return UnconstrainedBox(
      child: ProfileAvatarInherited(
        radius: size / 2.0,
        child: avatarWidget,
      ),
    );
  }
}

class ProfileBadge {
  final Widget badge;
  final Alignment alignment;

  ProfileBadge({required this.badge, this.alignment = Alignment.bottomRight});
}