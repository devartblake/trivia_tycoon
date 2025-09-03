import 'package:flutter/material.dart';

class SkillNodeWidget extends StatelessWidget {
  final String title;
  final bool unlocked;
  final VoidCallback onTap;

  const SkillNodeWidget({
    super.key,
    required this.title,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Container(
        width: 90,
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: unlocked ? Colors.amber : Colors.grey.shade400,
          border: Border.all(color: Colors.black87, width: 2),
          boxShadow: [
            if (unlocked)
              const BoxShadow(
                color: Colors.yellow,
                blurRadius: 10,
                spreadRadius: 2,
              )
          ],
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
