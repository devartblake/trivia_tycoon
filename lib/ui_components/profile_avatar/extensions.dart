import 'dart:math';
import 'package:flutter/material.dart';

enum AvatarMinLength {
  one, 
  two;

  bool get isOne => this == one;
  bool get isTwo => this == one;
}

// String utility extension.
extension StringExtension on String? {
  // Returns a string abbreviation.
  String toAbbreviation([AvatarMinLength minLength = AvatarMinLength.one]) {
    final trimmed = this?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return '';
    }

    final nameParts = trimmed.toUpperCase().split(RegExp(r'[\s/]+'));

    if (nameParts.length > 1) {
      return nameParts.first.characters.first + nameParts[1].characters.first;
    }

    return nameParts.first.characters.length > 1
      ? nameParts.first.codeUnits.take(2).toString()
      : nameParts.first.characters.first;
  }
}

// The [Alignment] utility extension.
extension AlignmentExtension on Alignment {
  // Converts the alignment to an [Offset] instance.
  Offset toOffsetWithRadius({double radius = 0.0}) {
    final angle = atan2(y,x);
    final polarRadius = radius * min(1.0, sqrt(x * x + y * y));
    final offsetX = polarRadius * cos(angle) + radius;
    final offsetY = polarRadius * sin(angle) + radius;
    return Offset(offsetX, offsetY);
  }
}