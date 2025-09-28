import 'package:flutter/material.dart';
import '../core/confetti_theme.dart';
import '../core/presets/confetti_presets.dart';

class ConfettiPresetSelector extends StatefulWidget {
  final Function(ConfettiTheme) onPresetSelected;

  const ConfettiPresetSelector({super.key, required this.onPresetSelected});

  @override
  State<ConfettiPresetSelector> createState() => _ConfettiPresetSelectorState();
}

class _ConfettiPresetSelectorState extends State<ConfettiPresetSelector> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Presets',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ConfettiPresets.allPresets.length,
            itemBuilder: (context, index) {
              final preset = ConfettiPresets.allPresets[index];
              final isHovered = _hoveredIndex == index;

              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 16),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredIndex = index),
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: GestureDetector(
                    onTap: () => widget.onPresetSelected(preset),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(isHovered ? 1.05 : 1.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isHovered
                              ? const Color(0xFF667EEA)
                              : const Color(0xFFE2E8F0),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isHovered ? 0.1 : 0.04),
                            blurRadius: isHovered ? 15 : 8,
                            offset: Offset(0, isHovered ? 6 : 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: preset.colors.take(2).toList(),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.celebration,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            preset.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF667EEA).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${preset.colors.length} colors',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF667EEA),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
