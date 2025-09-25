import 'package:flutter/material.dart';

Future<bool?> showExitMatchConfirm(BuildContext context, {String title = 'Leave match?'}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: const Text('Are you sure you want to leave? Your progress may be lost.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Leave')),
      ],
    ),
  );
}
