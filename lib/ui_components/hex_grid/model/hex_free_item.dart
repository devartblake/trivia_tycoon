import 'package:flutter/material.dart';

/// One freely-placed hex item (already positioned in world/screen space by you).
class HexFreeItem {
  final String id;
  final Offset center;          // pixel-space center
  final double? sizeOverride;   // optional, defaults to grid hexSize
  final List<HexSubItem> subItems; // optional subnodes orbiting the parent

  const HexFreeItem({
    required this.id,
    required this.center,
    this.sizeOverride,
    this.subItems = const [],
  });

  HexFreeItem copyWith({
    String? id,
    Offset? center,
    double? sizeOverride,
    List<HexSubItem>? subItems,
  }) =>
      HexFreeItem(
        id: id ?? this.id,
        center: center ?? this.center,
        sizeOverride: sizeOverride ?? this.sizeOverride,
        subItems: subItems ?? this.subItems,
      );
}

/// A subnode relative to its parent. Positioned using polar offsets.
/// - [angleDeg]: 0° = +X (to the right), counter-clockwise positive.
/// - [radiusFactor]: distance from parent center in multiples of hexSize.
/// - [scale]: subnode radius factor relative to parent radius (0..1).
class HexSubItem {
  final String id;
  final double angleDeg;
  final double radiusFactor;
  final double scale;

  const HexSubItem({
    required this.id,
    required this.angleDeg,
    this.radiusFactor = 0.75,
    this.scale = 0.45,
  });
}
