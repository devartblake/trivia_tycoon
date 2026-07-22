import 'package:flutter/material.dart';
import 'package:synaptix/synaptix/theme/synaptix_theme_extension.dart';

/// A floating glass lens for navigation that "liquifies" as it slides between options.
class SegmentedSelectionHub extends StatefulWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final Color? color;

  const SegmentedSelectionHub({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.color,
  });

  @override
  State<SegmentedSelectionHub> createState() => _SegmentedSelectionHubState();
}

class _SegmentedSelectionHubState extends State<SegmentedSelectionHub> {
  @override
  Widget build(BuildContext context) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final accent = widget.color ?? synaptix?.accentGlow ?? Colors.cyanAccent;

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 8) / widget.items.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                left: widget.selectedIndex * itemWidth,
                width: itemWidth,
                height: 42,
                child: Container(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(widget.items.length, (index) {
                  final isSelected = index == widget.selectedIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onItemSelected(index),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                            fontFamily: synaptix?.headlineFont,
                          ),
                          child: Text(widget.items[index].toUpperCase()),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
