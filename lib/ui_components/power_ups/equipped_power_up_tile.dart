import 'package:flutter/material.dart';
import '../../game/models/power_up.dart';

class EquippedPowerUpTile extends StatelessWidget {
  final PowerUp powerUp;
  final int duration;
  final VoidCallback onClear;

  const EquippedPowerUpTile({
    super.key,
    required this.powerUp,
    required this.duration,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.yellow[100],
      child: ListTile(
        leading: Image.asset(powerUp.iconPath, height: 32),
        title: Text(powerUp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "${powerUp.duration ~/ 60}m ${powerUp.duration % 60}s remaining",
          style: const TextStyle(color: Colors.grey)
        ),
        trailing: IconButton(
          icon: const Icon(Icons.bolt),
          color: Colors.amber,
          onPressed: onClear,
        ),
      ),
    );
  }
}
