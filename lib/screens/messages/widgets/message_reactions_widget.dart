import 'package:flutter/material.dart';

class MessageReactions extends StatelessWidget {
  final List<String> reactions;
  const MessageReactions({super.key, required this.reactions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Wrap(
        spacing: 4,
        children: reactions
            .map((emoji) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5865F2).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 12)),
                ))
            .toList(),
      ),
    );
  }
}
