import 'dart:math';
import 'package:flutter/material.dart';

class WordPosition {
  final String word; // The placed word (might be reversed)
  final String originalWord; // The original word from the list
  final List<Point<int>> positions;
  final Color color;

  WordPosition({
    required this.word,
    required this.originalWord,
    required this.positions,
    required this.color,
  });
}
