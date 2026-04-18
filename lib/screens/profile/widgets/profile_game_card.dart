import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/settings/multi_profile_service.dart';
import '../../../game/providers/riverpod_providers.dart';
import './profile_animated_stats.dart';
import './profile_character_section.dart';
import './profile_progress_section.dart';
import './profile_study_group_section.dart';
import './profile_username_section.dart';

/// The main profile card containing avatar, stats, progress, study group,
/// friends button, and developer/admin actions.
class ProfileGameCard extends ConsumerWidget {
  const ProfileGameCard({
    super.key,
    required this.profile,
    required this.isAdmin,
    required this.adminModeEnabled,
    required this.onToggleAdmin,
  });

  final ProfileData profile;
  final bool isAdmin;
  final bool adminModeEnabled;
  final Future<void> Function(bool) onToggleAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/backgrounds/geometry_background.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8A2BE2).withValues(alpha: 0.92),
                      const Color(0xFF9370DB).withValues(alpha: 0.88),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Reset avatar button (top-left)
            Positioned(
              top: 20,
              left: 20,
              child: _buildGlassButton(
                icon: Icons.restore_rounded,
                tooltip: 'Reset Avatar',
                onPressed: () async {
                  await ref.read(profileAvatarControllerProvider.notifier).resetAvatar();
                },
              ),
            ),
            // Admin toggle + level badge (top-right)
            Positioned(
              top: 20,
              right: 20,
              child: Row(
                children: [
                  if (isAdmin) ...[
                    _buildGlassButton(
                      icon: adminModeEnabled
                          ? Icons.toggle_on
                          : Icons.toggle_off_outlined,
                      tooltip: adminModeEnabled ? 'Disable Admin' : 'Enable Admin',
                      onPressed: () => onToggleAdmin(!adminModeEnabled),
                      iconColor: adminModeEnabled
                          ? const Color(0xFF10B981)
                          : Colors.white70,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFBBF24),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Level ${profile.level}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  SizedBox(
                    height: 240,
                    child: ProfileCharacterSection(profile: profile),
                  ),
                  const SizedBox(height: 24),
                  ProfileUsernameSection(profile: profile),
                  const SizedBox(height: 24),
                  ProfileAnimatedStats(profile: profile),
                  const SizedBox(height: 24),
                  ProfileProgressSection(profile: profile),
                  const SizedBox(height: 24),
                  _buildFriendsButton(context),
                  const SizedBox(height: 16),
                  ProfileStudyGroupSection(profile: profile),
                  const SizedBox(height: 20),
                  _buildBottomActions(),
                  const SizedBox(height: 16),
                  _buildDeveloperActions(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color iconColor = Colors.white70,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/friends'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF40E0D0).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Friends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Recent Quizzes',
            icon: Icons.quiz_rounded,
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            label: 'Study Chat',
            icon: Icons.chat_bubble_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
            ),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperActions(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.push('/profile/enhanced/current_user_id?currentUserId=current_user_id&isOwnProfile=true');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'View Enhanced Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: adminModeEnabled
                  ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              )
                  : LinearGradient(
                colors: [Colors.grey.shade700, Colors.grey.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (adminModeEnabled
                      ? const Color(0xFF10B981)
                      : Colors.grey.shade700)
                      .withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    adminModeEnabled
                        ? Icons.admin_panel_settings_rounded
                        : Icons.security_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        adminModeEnabled ? 'All features unlocked' : 'Standard access',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: adminModeEnabled,
                  onChanged: onToggleAdmin,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white.withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.white70,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
