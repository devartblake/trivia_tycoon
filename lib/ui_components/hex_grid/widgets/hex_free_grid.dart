import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../model/coordinates.dart';
import '../model/hex_free_item.dart';
import '../math/hex_metrics.dart';
import '../math/hex_orientation.dart';

/// A free-form hex grid that can render either:
///  - by axial coordinates (coords-mode), or
///  - by explicit pixel centers (items-mode).
///
/// Enhanced with animated sub-nodes similar to circular_menu behavior.
class HexagonFreeGrid extends StatefulWidget {
  // ---- Mode A: Coordinates (axial) ----
  final Set<Coordinates>? coords;
  final Widget Function(Coordinates c)? buildTile;
  final Widget Function(Coordinates c)? buildChild;

  // ---- Mode B: Free items (pixel centers) ----
  final List<HexFreeItem>? items;
  final Widget Function(String id)? buildItem;
  final Widget Function(String id)? buildItemChild;

  /// Optional renderer for sub-nodes (items-mode only).
  /// If null, sub-nodes will use [buildItem]/[buildItemChild] with `subId`.
  final Widget Function(String parentId, String subId)? buildSubItem;

  // ---- Animation & Interaction Config ----
  final bool enableSubNodeAnimation;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool expandOnTap;
  final bool expandOnHover;
  final VoidCallback? onSubNodeExpanded;
  final VoidCallback? onSubNodeCollapsed;

  // ---- Common config ----
  final double hexSize;
  final double spacing;
  final HexOrientation orientation;

  const HexagonFreeGrid({
    super.key,
    // coords-mode
    this.coords,
    this.buildTile,
    this.buildChild,
    // items-mode
    this.items,
    this.buildItem,
    this.buildItemChild,
    this.buildSubItem,
    // animation config
    this.enableSubNodeAnimation = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutBack,
    this.expandOnTap = true,
    this.expandOnHover = false,
    this.onSubNodeExpanded,
    this.onSubNodeCollapsed,
    // common
    required this.hexSize,
    this.spacing = 0,
    this.orientation = HexOrientation.pointy,
  }) : assert(!(coords != null && items != null), 'Provide either coords or items.');

  @override
  State<HexagonFreeGrid> createState() => _HexagonFreeGridState();
}

class _HexagonFreeGridState extends State<HexagonFreeGrid>
    with TickerProviderStateMixin {
  // Track expanded state for each parent item
  final Map<String, bool> _expandedStates = {};
  final Map<String, AnimationController> _animationControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(HexagonFreeGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _initializeAnimations();
    }
  }

  void _initializeAnimations() {
    // Clean up old controllers
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    _expandedStates.clear();

    // Initialize for items with sub-nodes
    if (widget.items != null) {
      for (final item in widget.items!) {
        if (item.subItems.isNotEmpty) {
          _expandedStates[item.id] = false;

          final controller = AnimationController(
            duration: widget.animationDuration,
            vsync: this,
          );
          _animationControllers[item.id] = controller;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleExpansion(String itemId) {
    if (!widget.enableSubNodeAnimation) return;

    final isExpanded = _expandedStates[itemId] ?? false;
    final controller = _animationControllers[itemId];

    if (controller != null) {
      setState(() {
        _expandedStates[itemId] = !isExpanded;
      });

      if (!isExpanded) {
        controller.forward();
        widget.onSubNodeExpanded?.call();
      } else {
        controller.reverse();
        widget.onSubNodeCollapsed?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final coordsUsable = widget.coords != null && (widget.coords!.isNotEmpty || widget.items == null);
        final itemsUsable = widget.items != null && (widget.items!.isNotEmpty || widget.coords == null);

        final useCoords = coordsUsable && (widget.coords!.isNotEmpty || (widget.items == null || widget.items!.isEmpty));
        final useItems = !useCoords && itemsUsable;

        if (!useCoords && !useItems) return const SizedBox.shrink();

        if (useCoords && widget.buildTile == null) {
          return const SizedBox.shrink();
        }
        if (useItems && widget.buildItem == null) {
          return const SizedBox.shrink();
        }

        final baseTileSize = HexMetrics.tileSize(widget.hexSize, widget.orientation);

        final List<_Placement> placements = [];
        if (useCoords) {
          for (final c in widget.coords!) {
            final center = HexMetrics.axialToPixel(
              c.q, c.r, widget.hexSize + widget.spacing, widget.orientation,
            );
            placements.add(_Placement.coord(c, center));
          }
        } else if (useItems) {
          for (final it in widget.items!) {
            placements.add(_Placement.item(it, it.center));
          }
        }

        // Bounding box calculation
        var minX = double.infinity, minY = double.infinity;
        var maxX = -double.infinity, maxY = -double.infinity;

        void includeRect(Rect r) {
          if (r.left < minX) minX = r.left;
          if (r.top < minY) minY = r.top;
          if (r.right > maxX) maxX = r.right;
          if (r.bottom > maxY) maxY = r.bottom;
        }

        for (final p in placements) {
          if (p.kind == _PlacementKind.coord) {
            includeRect(Rect.fromCenter(
              center: p.center,
              width: baseTileSize.width,
              height: baseTileSize.height,
            ));
          } else {
            final item = p.item!;
            final parentRadius = item.sizeOverride ?? widget.hexSize;
            final parentSize = HexMetrics.tileSize(parentRadius, widget.orientation);
            includeRect(Rect.fromCenter(center: p.center, width: parentSize.width, height: parentSize.height));

            // Include expanded sub-nodes in bounds
            if (item.subItems.isNotEmpty) {
              for (final sub in item.subItems) {
                final offset = _polarOffset(sub.angleDeg, parentRadius * sub.radiusFactor);
                final subCenter = p.center + offset;
                final subRadius = parentRadius * sub.scale;
                final subSize = HexMetrics.tileSize(subRadius, widget.orientation);
                includeRect(Rect.fromCenter(center: subCenter, width: subSize.width, height: subSize.height));
              }
            }
          }
        }

        if (!minX.isFinite) return const SizedBox.shrink();

        final contentW = maxX - minX;
        final contentH = maxY - minY;
        final offX = constraints.maxWidth / 2 - (minX + contentW / 2);
        final offY = constraints.maxHeight / 2 - (minY + contentH / 2);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final p in placements)
              ..._buildPositioned(
                placement: p,
                offset: Offset(offX, offY),
                baseTileSize: baseTileSize,
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildPositioned({
    required _Placement placement,
    required Offset offset,
    required Size baseTileSize,
  }) {
    final results = <Widget>[];

    if (placement.kind == _PlacementKind.coord) {
      final center = placement.center + offset;
      final left = center.dx - baseTileSize.width / 2;
      final top = center.dy - baseTileSize.height / 2;

      final bg = widget.buildTile!(placement.coord!);
      final fg = widget.buildChild?.call(placement.coord!);

      results.add(Positioned(
        left: left,
        top: top,
        width: baseTileSize.width,
        height: baseTileSize.height,
        child: Stack(
          children: [
            Positioned.fill(child: bg),
            if (fg != null) Positioned.fill(child: fg),
          ],
        ),
      ));
      return results;
    }

    // Items-mode: render parent with interaction
    final item = placement.item!;
    final parentRadius = item.sizeOverride ?? widget.hexSize;
    final parentSize = HexMetrics.tileSize(parentRadius, widget.orientation);

    final parentCenter = placement.center + offset;
    final parentLeft = parentCenter.dx - parentSize.width / 2;
    final parentTop = parentCenter.dy - parentSize.height / 2;

    final parentBg = widget.buildItem!(item.id);
    final parentFg = widget.buildItemChild?.call(item.id);

    final bool hasSubItems = item.subItems.isNotEmpty;
    final Widget parentWidget = Stack(
      children: [
        Positioned.fill(child: parentBg),
        if (parentFg != null) Positioned.fill(child: parentFg),
      ],
    );

    // Wrap parent with interaction if it has sub-items
    final Widget interactiveParent = hasSubItems
        ? MouseRegion(
      onEnter: widget.expandOnHover ? (_) => _toggleExpansion(item.id) : null,
      child: GestureDetector(
        onTap: widget.expandOnTap ? () => _toggleExpansion(item.id) : null,
        child: parentWidget,
      ),
    )
        : parentWidget;

    results.add(Positioned(
      left: parentLeft,
      top: parentTop,
      width: parentSize.width,
      height: parentSize.height,
      child: interactiveParent,
    ));

    // Items-mode: render animated sub-nodes
    if (hasSubItems && widget.enableSubNodeAnimation) {
      final controller = _animationControllers[item.id];

      if (controller != null) {
        for (int i = 0; i < item.subItems.length; i++) {
          final sub = item.subItems[i];

          results.add(_buildAnimatedSubNode(
            item: item,
            subItem: sub,
            parentCenter: parentCenter,
            parentRadius: parentRadius,
            controller: controller,
            index: i,
          ));
        }
      }
    } else if (hasSubItems && !widget.enableSubNodeAnimation) {
      // Static sub-nodes (original behavior)
      for (final sub in item.subItems) {
        results.add(_buildStaticSubNode(
          item: item,
          subItem: sub,
          parentCenter: parentCenter,
          parentRadius: parentRadius,
        ));
      }
    }

    return results;
  }

  Widget _buildAnimatedSubNode({
    required HexFreeItem item,
    required dynamic subItem, // Replace with your actual SubItem type
    required Offset parentCenter,
    required double parentRadius,
    required AnimationController controller,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Calculate staggered animation values
        final delay = index * 0.1;
        final adjustedProgress = ((controller.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);

        // Apply easing curve to the adjusted progress
        final easedProgress = widget.animationCurve.transform(adjustedProgress);

        // Calculate position with animation
        final animatedRadius = parentRadius * subItem.radiusFactor * easedProgress;
        final delta = _polarOffset(subItem.angleDeg, animatedRadius);
        final subCenter = parentCenter + delta;

        final subRadius = parentRadius * subItem.scale;
        final subSize = HexMetrics.tileSize(subRadius, widget.orientation);

        final subLeft = subCenter.dx - subSize.width / 2;
        final subTop = subCenter.dy - subSize.height / 2;

        final Widget subBg = (widget.buildSubItem != null)
            ? widget.buildSubItem!(item.id, subItem.id)
            : (widget.buildItem != null ? widget.buildItem!(subItem.id) : const SizedBox.shrink());
        final Widget? subFg = widget.buildItemChild?.call(subItem.id);

        return Positioned(
          left: subLeft,
          top: subTop,
          width: subSize.width,
          height: subSize.height,
          child: Transform.scale(
            scale: easedProgress,
            child: Opacity(
              opacity: easedProgress,
              child: Stack(
                children: [
                  Positioned.fill(child: subBg),
                  if (subFg != null) Positioned.fill(child: subFg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaticSubNode({
    required HexFreeItem item,
    required dynamic subItem,
    required Offset parentCenter,
    required double parentRadius,
  }) {
    final delta = _polarOffset(subItem.angleDeg, parentRadius * subItem.radiusFactor);
    final subCenter = parentCenter + delta;

    final subRadius = parentRadius * subItem.scale;
    final subSize = HexMetrics.tileSize(subRadius, widget.orientation);

    final subLeft = subCenter.dx - subSize.width / 2;
    final subTop = subCenter.dy - subSize.height / 2;

    final Widget subBg = (widget.buildSubItem != null)
        ? widget.buildSubItem!(item.id, subItem.id)
        : (widget.buildItem != null ? widget.buildItem!(subItem.id) : const SizedBox.shrink());
    final Widget? subFg = widget.buildItemChild?.call(subItem.id);

    return Positioned(
      left: subLeft,
      top: subTop,
      width: subSize.width,
      height: subSize.height,
      child: Stack(
        children: [
          Positioned.fill(child: subBg),
          if (subFg != null) Positioned.fill(child: subFg),
        ],
      ),
    );
  }

  Offset _polarOffset(double angleDeg, double radius) {
    final rad = angleDeg * math.pi / 180.0;
    return Offset(math.cos(rad) * radius, math.sin(rad) * radius);
  }
}

enum _PlacementKind { coord, item }

class _Placement {
  final _PlacementKind kind;
  final Coordinates? coord;
  final HexFreeItem? item;
  final Offset center;

  _Placement.coord(this.coord, this.center)
      : kind = _PlacementKind.coord,
        item = null;

  _Placement.item(this.item, this.center)
      : kind = _PlacementKind.item,
        coord = null;
}
