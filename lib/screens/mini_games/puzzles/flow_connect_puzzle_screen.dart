import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/models/flow_connect_grid_cell.dart';
import '../../../game/models/flow_connect_path_point.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../../game/services/flow_connect_level_generator.dart';
import '../../../game/state/flow_connect_game_state.dart';
import '../dialogs/flow_connect_settings_dialog.dart';
import '../dialogs/game_result_dialog.dart';

class FlowConnectPuzzleScreen extends ConsumerStatefulWidget {
  const FlowConnectPuzzleScreen({super.key});

  @override
  ConsumerState<FlowConnectPuzzleScreen> createState() => _FlowConnectPuzzleScreenState();
}

class _FlowConnectPuzzleScreenState extends ConsumerState<FlowConnectPuzzleScreen> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(flowConnectStateProvider);
    final gameState = notifier.gameState;

    // Listen for success status
    ref.listen(
      flowConnectStateProvider.select((state) => state.gameState.status),
          (previous, next) {
        if (next == FlowConnectGameStatus.success &&
            previous != FlowConnectGameStatus.success &&
            !_dialogShown) {
          _dialogShown = true;
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              _showResultDialog();
            }
          });
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text(
          'Flow Connect',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, size: 22),
            onPressed: () => _showHowToPlaySheet(context),
            tooltip: 'How to Play',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 22),
            onPressed: () => _showSettingsDialog(context),
            tooltip: 'Settings',
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _GameStatusHeader(status: gameState.status),
              const SizedBox(height: 24),
              const _GameGrid(),
              const SizedBox(height: 32),
              const _GameControls(),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDialog() {
    final notifier = ref.read(flowConnectStateProvider);
    final settings = ref.read(flowSettingsProvider);
    final time = notifier.completionTime;

    String achievementTitle = 'Flow Master!';
    String achievementSubtitle = 'All numbers connected perfectly';

    switch (settings.difficulty) {
      case FlowConnectDifficulty.easy:
        achievementTitle = 'Flow Solver!';
        achievementSubtitle = 'Easy puzzle completed';
        break;
      case FlowConnectDifficulty.medium:
        achievementTitle = 'Flow Expert!';
        achievementSubtitle = 'Medium puzzle mastered';
        break;
      case FlowConnectDifficulty.hard:
        achievementTitle = 'Flow Legend!';
        achievementSubtitle = 'Hard puzzle conquered';
        break;
    }

    GameResultScreen.show(
      context: context,
      config: GameResultConfig(
        gameTitle: 'Flow Connect - ${settings.difficulty.name.toUpperCase()}',
        completionTime: time,
        achievementTitle: achievementTitle,
        achievementSubtitle: achievementSubtitle,
        totalPlays: 1,
        winPercentage: 100,
        bestScore: time,
        currentStreak: 1,
        primaryColor: const Color(0xFF6366F1),
        gameIcon: Icons.timeline,
      ),
      onShare: () {
        debugPrint('Share tapped');
      },
      onClose: () {
        _dialogShown = false;
      },
      onPlayAgain: () {
        setState(() {
          _dialogShown = false;
        });
        ref.read(flowConnectStateProvider).initializeGame(
          settings.gridSize,
          settings.difficulty,
        );
      },
    );
  }

  void _showHowToPlaySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _HowToPlayContent(),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const FlowConnectSettingsDialog(),
    );
  }
}

class _GameStatusHeader extends ConsumerWidget {
  final FlowConnectGameStatus status;
  const _GameStatusHeader({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String message;
    Color bgColor;
    Color textColor;
    IconData? icon;

    switch (status) {
      case FlowConnectGameStatus.notStarted:
        message = 'Connect numbers in sequence';
        bgColor = const Color(0xFF6366F1).withValues(alpha: 0.1);
        textColor = const Color(0xFF6366F1);
        icon = Icons.info_outline_rounded;
        break;
      case FlowConnectGameStatus.playing:
        final currentNum = ref.watch(flowConnectStateProvider.select((p) => p.gameState.currentNumber));
        final totalNums = ref.watch(flowConnectStateProvider.select((p) => p.gameState.totalNumbers));
        final displayNum = (currentNum > totalNums) ? totalNums : currentNum;
        message = 'Find number $displayNum of $totalNums';
        bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.1);
        textColor = const Color(0xFF3B82F6);
        icon = Icons.play_circle_outline_rounded;
        break;
      case FlowConnectGameStatus.success:
        message = 'Puzzle Solved!';
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
        textColor = const Color(0xFF10B981);
        icon = Icons.check_circle_outline_rounded;
        break;
      case FlowConnectGameStatus.failed:
        message = 'Incorrect Path!';
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
        textColor = const Color(0xFFEF4444);
        icon = Icons.error_outline_rounded;
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey<String>(message),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...[
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
          ],
            Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameGrid extends ConsumerWidget {
  const _GameGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(flowConnectStateProvider);
    final gameState = notifier.gameState;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardSize = constraints.maxWidth.clamp(0, 500);
        final double cellSize = boardSize / gameState.gridSize;

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: _PathPainter(
                      path: gameState.currentPath,
                      cellSize: cellSize,
                      hintPoint: notifier.hintPoint,
                    ),
                  ),
                  GestureDetector(
                    onPanStart: (details) => notifier.onPanStart(details.localPosition, cellSize),
                    onPanUpdate: (details) => notifier.onPanUpdate(details.localPosition, cellSize),
                    onPanEnd: (_) => notifier.onPanEnd(),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gameState.gridSize,
                      ),
                      itemCount: gameState.gridSize * gameState.gridSize,
                      itemBuilder: (context, index) {
                        final row = index ~/ gameState.gridSize;
                        final col = index % gameState.gridSize;
                        return _GridCell(
                          cell: gameState.grid[row][col],
                          isPath: gameState.currentPath.any((p) => p.row == row && p.col == col),
                          isHint: notifier.hintPoint?.row == row && notifier.hintPoint?.col == col,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridCell extends StatelessWidget {
  final FlowConnectGridCell cell;
  final bool isPath;
  final bool isHint;

  const _GridCell({required this.cell, required this.isPath, required this.isHint});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isHint
            ? const Color(0xFFFBBF24).withValues(alpha: 0.15)
            : (isPath ? const Color(0xFF6366F1).withValues(alpha: 0.08) : Colors.transparent),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 0.5,
        ),
      ),
      child: cell.number != null
          ? Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isPath
                  ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                  : [const Color(0xFF3B82F6), const Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: (isPath ? const Color(0xFF6366F1) : const Color(0xFF3B82F6)).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              cell.number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      )
          : null,
    );
  }
}

class _GameControls extends ConsumerWidget {
  const _GameControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(flowConnectStateProvider.select((s) => s.gameState));
    final notifier = ref.read(flowConnectStateProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            color: const Color(0xFF64748B),
            onPressed: gameState.canUndo ? notifier.undo : null,
          ),
          _ControlButton(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Hint',
            color: const Color(0xFFF59E0B),
            onPressed: notifier.showHint,
          ),
          _ControlButton(
            icon: Icons.refresh_rounded,
            label: 'New',
            color: const Color(0xFF6366F1),
            onPressed: () {
              final settings = ref.read(flowSettingsProvider);
              notifier.initializeGame(settings.gridSize, settings.difficulty);
            },
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Icon(icon, size: 24, color: color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToPlayContent extends StatelessWidget {
  const _HowToPlayContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'How to Play',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _RuleItem(
            icon: Icons.looks_one_rounded,
            text: 'Start at the number 1.',
            color: Color(0xFF6366F1),
          ),
          const _RuleItem(
            icon: Icons.linear_scale_rounded,
            text: 'Connect all numbers in sequential order (1 → 2 → 3...).',
            color: Color(0xFF3B82F6),
          ),
          const _RuleItem(
            icon: Icons.grid_on_rounded,
            text: 'The path must fill every single cell on the grid.',
            color: Color(0xFF10B981),
          ),
          const _RuleItem(
            icon: Icons.close_rounded,
            text: 'The path cannot cross over itself.',
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Got It!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _RuleItem({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final List<FlowConnectPathPoint> path;
  final double cellSize;
  final FlowConnectPathPoint? hintPoint;

  _PathPainter({required this.path, required this.cellSize, this.hintPoint});

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      )
      ..strokeWidth = cellSize * 0.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.2)
      ..strokeWidth = cellSize * 0.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final uiPath = ui.Path();
    final firstPoint = path.first;
    uiPath.moveTo(
      firstPoint.col * cellSize + cellSize / 2,
      firstPoint.row * cellSize + cellSize / 2,
    );

    for (int i = 1; i < path.length; i++) {
      final point = path[i];
      uiPath.lineTo(
        point.col * cellSize + cellSize / 2,
        point.row * cellSize + cellSize / 2,
      );
    }

    canvas.drawPath(uiPath, shadowPaint);
    canvas.drawPath(uiPath, paint);

    if (hintPoint != null) {
      final hintPaint = Paint()..color = const Color(0xFFFBBF24).withValues(alpha: 0.6);
      final hintBorderPaint = Paint()
        ..color = const Color(0xFFFBBF24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        Offset(
          hintPoint!.col * cellSize + cellSize / 2,
          hintPoint!.row * cellSize + cellSize / 2,
        ),
        cellSize * 0.25,
        hintPaint,
      );
      canvas.drawCircle(
        Offset(
          hintPoint!.col * cellSize + cellSize / 2,
          hintPoint!.row * cellSize + cellSize / 2,
        ),
        cellSize * 0.25,
        hintBorderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.path != path || oldDelegate.hintPoint != hintPoint;
  }
}
