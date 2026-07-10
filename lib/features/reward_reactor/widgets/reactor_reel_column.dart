import 'package:flutter/material.dart';

import 'reactor_symbol_tile.dart';

class ReactorReelColumn extends StatefulWidget {
  final List<String> symbols;
  final int winningSymbolIndex;
  final bool isSpinning;
  final Duration stopDelay;
  final VoidCallback? onStopped;
  final String? seasonKey;

  const ReactorReelColumn({
    super.key,
    required this.symbols,
    required this.winningSymbolIndex,
    required this.isSpinning,
    this.stopDelay = Duration.zero,
    this.onStopped,
    this.seasonKey,
  });

  @override
  State<ReactorReelColumn> createState() => _ReactorReelColumnState();
}

class _ReactorReelColumnState extends State<ReactorReelColumn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scrollAnimation;

  static const int _visibleTiles = 3;
  static const double _tileHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scrollAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onStopped?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ReactorReelColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      Future.delayed(widget.stopDelay, () {
        if (mounted) _controller.forward(from: 0);
      });
    } else if (!widget.isSpinning && oldWidget.isSpinning) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _displaySymbols {
    final count = widget.symbols.length;
    if (count == 0) return List.filled(_visibleTiles + 2, 'coin');

    final extendedSymbols = <String>[];
    for (int i = 0; i < (count + _visibleTiles); i++) {
      extendedSymbols.add(widget.symbols[i % count]);
    }
    return extendedSymbols;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: 72,
        height: _tileHeight * _visibleTiles,
        child: AnimatedBuilder(
          animation: _scrollAnimation,
          builder: (context, _) {
            final count = widget.symbols.isEmpty ? 1 : widget.symbols.length;
            final totalScrollHeight = _tileHeight * (count + _visibleTiles);

            final offset = widget.isSpinning
                ? _scrollAnimation.value * totalScrollHeight
                : 0.0;

            return Transform.translate(
              offset: Offset(0, -offset),
              child: Column(
                children: _displaySymbols.asMap().entries.map((entry) {
                  final count =
                      widget.symbols.isEmpty ? 1 : widget.symbols.length;
                  final isWinning = !widget.isSpinning &&
                      entry.key == 1 &&
                      entry.value ==
                          widget.symbols[widget.winningSymbolIndex % count];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ReactorSymbolTile(
                      symbolKey: entry.value,
                      isWinning: isWinning,
                      seasonKey: widget.seasonKey,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
