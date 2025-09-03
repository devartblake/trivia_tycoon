import 'package:flutter/material.dart';

class SlideToExpandCard extends StatefulWidget {
  final Widget collapsedContent;
  final Widget expandedContent;

  const SlideToExpandCard({
    super.key,
    required this.collapsedContent,
    required this.expandedContent,
  });

  @override
  State<SlideToExpandCard> createState() => _SlideToExpandCardState();
}

class _SlideToExpandCardState extends State<SlideToExpandCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            widget.collapsedContent,
            if (_expanded)
              Column(
                children: [
                  const SizedBox(height: 12),
                  widget.expandedContent,
                ],
              )
          ],
        ),
      ),
    );
  }
}