import 'package:flutter/material.dart';

class SwipeToRevealCard extends StatelessWidget {
  final Widget content;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const SwipeToRevealCard({
    super.key,
    required this.content,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        } else if (direction == DismissDirection.startToEnd) {
          onEdit();
        }
      },
      child: Card(child: content),
    );
  }
}