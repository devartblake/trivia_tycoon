import 'dart:math';

import 'package:flutter/material.dart';
import '../../../game/controllers/word_search_controller.dart';

class WordSearchGrid extends StatelessWidget {
  final WordSearchController controller;

  const WordSearchGrid({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gridWidth = constraints.maxWidth;
              final cellSize = (gridWidth - 22) / 12; // Account for spacing

              return GestureDetector(
                onPanStart: (details) {
                  final position = _getCellFromPosition(details.localPosition, cellSize);
                  if (position != null) {
                    controller.onDragStart(position.x, position.y);
                  }
                },
                onPanUpdate: (details) {
                  final position = _getCellFromPosition(details.localPosition, cellSize);
                  if (position != null) {
                    controller.onDragUpdate(position.x, position.y);
                  }
                },
                onPanEnd: (_) => controller.onDragEnd(),
                onPanCancel: () => controller.onDragEnd(),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 12,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: 144,
                  itemBuilder: (context, index) {
                    final row = index ~/ 12;
                    final col = index % 12;
                    return _buildCell(row, col);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Point<int>? _getCellFromPosition(Offset position, double cellSize) {
    // Account for spacing between cells
    final col = (position.dx / (cellSize + 2)).floor();
    final row = (position.dy / (cellSize + 2)).floor();

    if (row >= 0 && row < 12 && col >= 0 && col < 12) {
      return Point(row, col);
    }
    return null;
  }

  Widget _buildCell(int row, int col) {
    final highlight = controller.getCellHighlight(row, col);
    final isSelected = controller.isCellSelected(row, col);

    return Container(
      decoration: BoxDecoration(
        color: highlight ?? (isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.3) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          controller.grid[row][col],
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: highlight != null ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
