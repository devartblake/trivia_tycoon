import 'package:flutter/material.dart';
import '../../../game/models/question_model.dart';
import 'question_power_ups.dart';

/// Drag-and-drop question renderer
class DragDropView extends StatefulWidget {
  final QuestionModel question;
  final void Function(Map<String, String>)?
      onAnswerSelected; // Maps item to target
  final bool showFeedback;
  final Map<String, String>? selectedAnswer; // Current mapping
  final bool isMultiplayer;

  const DragDropView({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    this.showFeedback = false,
    this.selectedAnswer,
    this.isMultiplayer = false,
  });

  @override
  State<DragDropView> createState() => _DragDropViewState();
}

class _DragDropViewState extends State<DragDropView> {
  late Map<String, String> currentMapping;
  late List<String> draggableItems;
  late Set<String> targetZones;

  @override
  void initState() {
    super.initState();
    currentMapping = widget.selectedAnswer ?? {};
    // Parse draggable items from question options
    draggableItems = widget.question.options;
    // Parse target zones from reduced options or tags
    targetZones = Set.from(widget.question.tags ?? ['Target 1', 'Target 2']);
  }

  void _onItemDropped(String item, String target) {
    if (widget.showFeedback) return; // Can't change answer during feedback

    setState(() {
      currentMapping[item] = target;
    });

    if (widget.onAnswerSelected != null) {
      widget.onAnswerSelected!(currentMapping);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isMultiplayer) const MultiplayerBadge(),
        Text(
          widget.question.question,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        if (widget.question.isBoostedTime ||
            widget.question.isShielded ||
            widget.question.multiplier != null)
          PowerUpIndicators(
            isBoostedTime: widget.question.isBoostedTime,
            isShielded: widget.question.isShielded,
            multiplier: widget.question.multiplier,
          ),
        if (widget.question.showHint &&
            widget.question.powerUpHint?.isNotEmpty == true)
          HintPanel(hint: widget.question.powerUpHint!),
        const SizedBox(height: 24),
        // Draggable items (left side)
        Text(
          'Drag items to the targets:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: draggableItems.map((item) {
            return Draggable<String>(
              data: item,
              feedback: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: _buildItemChip(item),
              ),
              child: _buildItemChip(item),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        // Target zones (right side)
        Text(
          'Drop targets:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: targetZones.map((target) {
            final itemsInTarget = currentMapping.entries
                .where((e) => e.value == target)
                .map((e) => e.key)
                .toList();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DragTarget<String>(
                onAcceptWithDetails: (details) =>
                    _onItemDropped(details.data, target),
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: candidateData.isNotEmpty
                            ? Colors.green.shade600
                            : Colors.grey.shade300,
                        width: candidateData.isNotEmpty ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: candidateData.isNotEmpty
                          ? Colors.green.shade50
                          : Colors.grey.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          target,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (itemsInTarget.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            children: itemsInTarget.map((item) {
                              return Chip(
                                label: Text(item),
                                backgroundColor: Colors.blue.shade100,
                                onDeleted: !widget.showFeedback
                                    ? () {
                                        setState(() {
                                          currentMapping.remove(item);
                                        });
                                        if (widget.onAnswerSelected != null) {
                                          widget.onAnswerSelected!(
                                              currentMapping);
                                        }
                                      }
                                    : null,
                              );
                            }).toList(),
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Drop here',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
        if (widget.showFeedback) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Text(
              'Review your mapping above',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItemChip(String item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Text(
        item,
        style: TextStyle(
          color: Colors.blue.shade900,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
