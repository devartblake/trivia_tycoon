import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../game/controllers/settings_controller.dart';
import '../../game/providers/riverpod_providers.dart';

final settingsControllerProvider = Provider<SettingsController>((ref) {
  final manager = ref.read(serviceManagerProvider);
  return SettingsController(
    audioService: manager.audioSettingsService,
    profileService: manager.playerProfileService,
    purchaseService: manager.purchaseSettingsService,
  );
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final SettingsController settingsController;

  @override
  void initState() {
    super.initState();
    settingsController = ref.read(settingsControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        children: [
          SingleSection(
              title: "General",
              children: [
                _buildAudioToggle("Enable Audio", settingsController.audioOn, settingsController.toggleAudioOn),
                _buildAudioToggle("Enable Music", settingsController.musicOn, settingsController.toggleMusicOn),
                _buildAudioToggle("Enable Sound Effect", settingsController.soundsOn, settingsController.toggleSoundsOn),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.color_lens),
                  title: const Text("Theme Settings"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/theme-settings');
                  },
                ),
              ]
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text("Confetti Settings"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/confetti-settings');
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text("Available songs", style: TextStyle(fontWeight: FontWeight.bold),),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/music');
            },
          ),

          const Divider(),

          SingleSection(
            title: "Preferences",
            children: [
              CustomListTile(
                  title: "Newsletter",
                  icon: Icons.newspaper_rounded
              ),
              CustomListTile(
                  title: "Questions with images",
                  icon: Icons.question_answer_rounded
              ),
            ],
          ),

          const Divider(),

          SingleSection(
            title: "Privacy and Security",
            children: [
              CustomListTile(
                  title: "Help & Feedback",
                  icon: Icons.help_outline_rounded
              ),
              CustomListTile(
                  title: "About",
                  icon: Icons.info_outline_rounded
              ),
              CustomListTile(
                  title: "Sign out",
                  icon: Icons.exit_to_app_rounded
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildAudioToggle(String title, ValueNotifier<bool> valueNotifier, VoidCallback toggleFunction) {
  return ListTile(
    title: Text(title),
    trailing: ValueListenableBuilder<bool>(
        valueListenable: valueNotifier,
        builder: (context, value, _) {
          return Switch(value: value, onChanged: (_) => toggleFunction());
        }
    ),
  );
}

class CustomListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final  Widget? trailing;

  const CustomListTile({
    required this.title,
    required this.icon,
    this.trailing,
    super.key
  });

  @override
  Widget build(BuildContext context)
  {
    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
      onTap: () {},
    );
  }
}

class SingleSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SingleSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
          ),
        ),
        Container(
          width: double.infinity,
          color: Colors.white,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}