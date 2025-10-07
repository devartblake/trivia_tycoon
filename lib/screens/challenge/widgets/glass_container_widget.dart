import 'package:flutter/material.dart';
import '../../../ui_components/expansion_tile_card/expansion_tile_card.dart';

/// Glass-style card container (Impeller-safe, no BackdropFilter)
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color tint;
  final Color borderColor;
  final bool elevated;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.tint = const Color(0x22FFFFFF), // Semi-transparent white
    this.borderColor = const Color(0x44FFFFFF), // Subtle white border
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: elevated
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: child,
    );
  }
}

/// Compact glass info card for headers/footers
class CompactGlassCard extends StatelessWidget {
  final Widget child;
  final Color? tint;
  final Color? borderColor;

  const CompactGlassCard({
    super.key,
    required this.child,
    this.tint,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tint ?? const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? const Color(0x55FFFFFF),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Glass Expansion Tile Card - combines ExpansionTileCard with glass aesthetic
class GlassExpansionCard extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final List<Widget> children;
  final Widget? trailing;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final Color? tint;
  final Color? borderColor;
  final Color? expandedTint;
  final double borderRadius;
  final bool dense;

  const GlassExpansionCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.children = const [],
    this.trailing,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.tint,
    this.borderColor,
    this.expandedTint,
    this.borderRadius = 20,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTint = const Color(0x22FFFFFF);
    final defaultBorder = const Color(0x44FFFFFF);
    final defaultExpandedTint = const Color(0x33FFFFFF);

    return ExpansionTileCard(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      dense: dense,
      borderRadius: BorderRadius.circular(borderRadius),
      elevation: 4,
      initialElevation: 2,
      baseColor: tint ?? defaultTint,
      expandedColor: expandedTint ?? defaultExpandedTint,
      shadowColor: Colors.black.withOpacity(0.08),
      duration: const Duration(milliseconds: 300),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      initialPadding: EdgeInsets.zero,
      finalPadding: const EdgeInsets.only(bottom: 8),
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: borderColor ?? defaultBorder,
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

/// Collapsed (non-expandable) version of ExpansionTileCard
class CollapsedTileCard extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? tint;
  final Color? borderColor;
  final double borderRadius;
  final bool dense;
  final EdgeInsetsGeometry? contentPadding;

  const CollapsedTileCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.tint,
    this.borderColor,
    this.borderRadius = 20,
    this.dense = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTint = const Color(0x22FFFFFF);
    final defaultBorder = const Color(0x44FFFFFF);

    return Material(
      type: MaterialType.card,
      color: tint ?? defaultTint,
      borderRadius: BorderRadius.circular(borderRadius),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor ?? defaultBorder,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: ListTile(
            dense: dense,
            contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: leading,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
          ),
        ),
      ),
    );
  }
}

/// Legacy compatibility aliases
typedef LightCard = GlassExpansionCard;
typedef CompactInfoCard = CompactGlassCard;