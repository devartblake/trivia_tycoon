import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/multiplayer/providers/multiplayer_providers.dart';
import '../widgets/room_card.dart';

Future<String?> showSelectRoomDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _SelectRoomDialog(),
  );
}

class _SelectRoomDialog extends ConsumerWidget {
  const _SelectRoomDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Select a Room'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: ref.read(multiplayerServiceProvider).listRooms(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rooms = snapshot.data!;
            if (rooms.isEmpty) {
              return const Center(child: Text('No rooms available'));
            }
            return ListView.separated(
              itemCount: rooms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => RoomCard.fromJson(
                json: rooms[i],
                onTap: () => Navigator.of(context).pop((rooms[i]['roomId'] ?? '').toString()),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}
