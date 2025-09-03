import 'package:flutter/material.dart';

class ScanTypeIcon extends StatelessWidget {
  final String type;

  const ScanTypeIcon({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case 'url':
        icon = Icons.link;
        color = Colors.blue;
        break;
      case 'userId':
        icon = Icons.person;
        color = Colors.deepPurple;
        break;
      case 'json':
        icon = Icons.code;
        color = Colors.orange;
        break;
      default:
        icon = Icons.qr_code;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color),
    );
  }
}
