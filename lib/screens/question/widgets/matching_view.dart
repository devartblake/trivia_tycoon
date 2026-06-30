import 'package:flutter/material.dart';
import '../../../game/models/question_model.dart';
import 'question_power_ups.dart';

/// Matching pairs question renderer
class MatchingView extends StatefulWidget {
  final QuestionModel question;
  final void Function(Map<String, String>)? onAnswerSelected; // Maps left items to right items
  final bool showFeedback;
  final Map<String, String>? selectedAnswer; // Current mappings
  final bool isMultiplayer;

  const MatchingView({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    this.showFeedback = false,
    this.selectedAnswer,
    this.isMultiplayer = false,
  });

  @override
  State<MatchingView> createState() => _MatchingViewState();
}

class _MatchingViewState extends State<MatchingView> {
  late Map<String, String> currentMatches;
  late List<String> leftItems;
  late List<String> rightItems;
  late Map<String, List<Offset>> connections;
  String? _selectedLeftItem;

  @override
  void initState() {
    super.initState();
    currentMatches = widget.selectedAnswer ?? {};
    // Parse left items from question options (first half)
    leftItems = widget.question.options.take((widget.question.options.length / 2).ceil()).toList();
    // Parse right items from question options (second half) or tags
    rightItems = widget.question.tags ?? [];
    if (rightItems.isEmpty && widget.question.options.length > leftItems.length) {
      rightItems = widget.question.options.skip(leftItems.length).toList();
    }
    connections = {};
  }

  void _selectLeftItem(String item) {
    if (widget.showFeedback) return;

    setState(() {
      if (_selectedLeftItem == item) {
        _selectedLeftItem = null; // Deselect
      } else {
        _selectedLeftItem = item;
      }
    });
  }

  void _matchWithRight(String rightItem) {
    if (widget.showFeedback || _selectedLeftItem == null) return;

    setState(() {
      currentMatches[_selectedLeftItem!] = rightItem;
      _selectedLeftItem = null;
    });

    if (widget.onAnswerSelected != null) {
      widget.onAnswerSelected!(currentMatches);
    }
  }

  void _removeMatch(String leftItem) {
    if (widget.showFeedback) return;

    setState(() {
      currentMatches.remove(leftItem);
    });

    if (widget.onAnswerSelected != null) {
      widget.onAnswerSelected!(currentMatches);
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
        if (widget.question.showHint && widget.question.powerUpHint?.isNotEmpty == true)
          HintPanel(hint: widget.question.powerUpHint!),
        const SizedBox(height: 24),
        Text(
          'Match pairs by selecting an item on the left and clicking on the right:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        // Two-column layout
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                children: leftItems.map((leftItem) {
                  final isMatched = currentMatches.containsKey(leftItem);
                  final matchedRight = isMatched ? currentMatches[leftItem] : null;
                  final isSelected = _selectedLeftItem == leftItem;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _selectLeftItem(leftItem),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.shade600
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? Colors.blue.shade50
                              : (isMatched ? Colors.green.shade50 : Colors.white),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leftItem,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            if (isMatched) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Matched: $matchedRight',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!widget.showFeedback)
                                    GestureDetector(
                                      onTap: () => _removeMatch(leftItem),
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 24),
            // Right column
            Expanded(
              child: Column(
                children: rightItems.map((rightItem) {
                  final isMatched = currentMatches.containsValue(rightItem);
                  final matchedLeft = currentMatches.entries
                      .firstWhere(
                        (e) => e.value == rightItem,
                        orElse: () => MapEntry('', ''),
                      )
                      .key;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _matchWithRight(rightItem),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedLeftItem != null
                                ? Colors.orange.shade300
                                : Colors.grey.shade300,
                            width: _selectedLeftItem != null ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isMatched
                              ? Colors.green.shade50
                              : (_selectedLeftItem != null
                                  ? Colors.orange.shade50
                                  : Colors.white),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rightItem,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            if (isMatched) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'From: $matchedLeft',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
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
              'Review your matches above',
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
