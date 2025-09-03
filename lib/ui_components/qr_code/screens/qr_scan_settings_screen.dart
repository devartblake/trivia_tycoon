import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/riverpod_providers.dart';

class QrScanSettingsScreen extends ConsumerWidget {
  const QrScanSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(qrSettingsProvider);
    final notifier = ref.read(qrSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('QR Scan Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Auto-Launch URLs"),
            value: settings.autoLaunch,
            onChanged: (value) => notifier.updateAutoLaunch(value)
          ),
          const Divider(),
          ListTile(
            title: const Text("Scan History Limit"),
            subtitle: Text("Currently: ${settings.scanLimit} items"),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await showDialog<int>(
                  context: context,
                  builder: (_) => _EditLimitDialog(initial: settings.scanLimit),
                );
                if (result != null && result > 0) {
                  await notifier.updateScanLimit(result);
                }
              },
            ),
          ),
        ],
      )
    );
  }
}

class _EditLimitDialog extends StatefulWidget {
  final int initial;
  const _EditLimitDialog({required this.initial});

  @override
  State<_EditLimitDialog> createState() => _EditLimitDialogState();
}

class _EditLimitDialogState extends State<_EditLimitDialog> {
  late int limit;

  @override
  void initState() {
    super.initState();
    limit = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Set History Limit"),
      content: TextFormField(
        initialValue: limit.toString(),
        keyboardType: TextInputType.number,
        onChanged: (v) => limit = int.tryParse(v) ?? widget.initial,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: () => Navigator.pop(context, limit), child: const Text("Save")),
      ],
    );
  }
}
