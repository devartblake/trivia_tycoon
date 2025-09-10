import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/profile/widgets/shimmer_avatar.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../profile/widgets/theme_drawer.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(profileAvatarControllerProvider);
    final path = controller.effectiveAvatarPath;

    return ThemedDrawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              accountName: const Text('John Doe', style: TextStyle(color: Colors.black)),
              accountEmail: const Text('john.doe@example.com', style: TextStyle(color: Colors.black)),
              currentAccountPicture: Hero(
                tag: 'profile-avatar',
                child: ShimmerAvatar(
                  avatarPath: path,
                  isOnline: true,
                  isLoading: false,
                ),
              ),
              otherAccountsPictures: [
                IconButton(
                  icon: const Icon(Icons.account_circle, color: Colors.white),
                  tooltip: "Profile",
                  onPressed: () {
                    context.push('/profile');
                  },
                )
              ],
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                context.go('/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Play Quiz'),
              onTap: () {
                context.push('/quiz');
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Skills'),
              onTap: () {
                context.push('/skills');
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Skills Test'),
              onTap: () {
                context.push('/skills-test');
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Rewards'),
              onTap: () {
                context.push('/rewards');
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('Leaderboard'),
              onTap: () {
                context.push('/leaderboard');
              },
            ),
            const Divider(),
            ExpansionTile(
              leading: const Icon(Icons.more_horiz),
              title: const Text('More Options'),
              children: [
                ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('Friends'),
                  onTap: () => context.push('/friends'),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_suggest),
                  title: const Text('Preferences'),
                  onTap: () => context.push('/preferences'),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Feedback'),
                  onTap: () => context.push('/help'),
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Administrator'),
              onTap: () {
                context.push('/admin');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                context.push('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report'),
              onTap: () {
                context.push('/report');
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
  }
}
