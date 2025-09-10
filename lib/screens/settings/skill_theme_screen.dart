import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/hex_spider_theme.dart';
import '../../game/providers/hex_theme_providers.dart';

final hexSpiderThemeProvider =
StateProvider<HexSpiderTheme>((ref) => HexSpiderTheme.brand);

class SkillThemeScreen extends ConsumerWidget {
  const SkillThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(hexSpiderThemeProvider);
    final snap  = ref.watch(hexSnapToNodesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Skill Tree Background', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Theme dropdown
          DropdownButtonFormField<HexSpiderTheme>(
            value: theme,
            decoration: const InputDecoration(labelText: 'Theme'),
            items: const [
              DropdownMenuItem(value: HexSpiderTheme.brand,     child: Text('Brand')),
              DropdownMenuItem(value: HexSpiderTheme.jamaica,   child: Text('Jamaican Flag')),
              DropdownMenuItem(value: HexSpiderTheme.usa,       child: Text('American Flag')),
              DropdownMenuItem(value: HexSpiderTheme.pinterest, child: Text('Pinterest')),
              DropdownMenuItem(value: HexSpiderTheme.neon,      child: Text('Neon')),
            ],
            onChanged: (v) {
              if (v != null) {
                ref.read(hexSpiderThemeProvider.notifier).state = v;
              }
            },
          ),

          const SizedBox(height: 16),

          // Snap toggle
          SwitchListTile(
            title: const Text('Snap background grid to nodes'),
            value: snap,
            onChanged: (v) => ref.read(hexSnapToNodesProvider.notifier).state = v,
          ),
        ],
      ),
    );
  }
}