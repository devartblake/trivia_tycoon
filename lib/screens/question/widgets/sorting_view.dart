import 'package:flutter/material.dart';
import '../../../game/models/question_model.dart';
import 'question_power_ups.dart';

/// Sorting/ordering question renderer
class SortingView extends StatefulWidget {
  final QuestionModel question;
  final void Function(List<String>)? onAnswerSelected; // Ordered list
  final bool showFeedback;
  final List<String>? selectedAnswer; // Current order
  final bool isMultiplayer;

  const SortingView({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    this.showFeedback = false,
    this.selectedAnswer,
    this.isMultiplayer = false,
  });

  @override
  State<SortingView> createState() => _SortingViewState();
}

class _SortingViewState extends State<SortingView> {
  late List<String> currentOrder;

  @override
  void initState() {
    super.initState();
    currentOrder =
        widget.selectedAnswer ?? List<String>.from(widget.question.options);
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (widget.showFeedback) return; // Can't change answer during feedback

    setState(() {
      final item = currentOrder.removeAt(oldIndex);
      currentOrder.insert(newIndex, item);
    });

    if (widget.onAnswerSelected != null) {
      widget.onAnswerSelected!(currentOrder);
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
        Text(
          'Drag items to reorder them:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        ReorderableListView(
          onReorderItem: !widget.showFeedback ? _onReorder : (_, __) {},
          children: currentOrder.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Padding(
              key: ValueKey(item),
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue.shade50,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (!widget.showFeedback)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.drag_handle,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      // Order badge
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.shade600,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Item text
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
              'Review the order above',
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
}
