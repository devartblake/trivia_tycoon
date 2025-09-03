import 'package:flutter/material.dart';

class MissionSwapButton extends StatelessWidget {
  final VoidCallback onPressed;

  const MissionSwapButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.only(top: 4, right: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.refresh, color: Colors.grey),
          onPressed: onPressed,
          tooltip: "Swap mission",
        ),
      ),
    );
  }
}
