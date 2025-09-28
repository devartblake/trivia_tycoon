import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/analytics/managers/profile_analytics_manager.dart';
import '../../../game/providers/multi_profile_providers.dart';
import '../../../core/manager/log_manager.dart';

class CreateProfileDialog extends ConsumerStatefulWidget {
  final VoidCallback onProfileCreated;

  const CreateProfileDialog({
    super.key,
    required this.onProfileCreated,
  });

  @override
  ConsumerState<CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends ConsumerState<CreateProfileDialog> {
  final _nameController = TextEditingController();
  String _selectedAgeGroup = 'teens';
  String? _selectedAvatar;
  bool _isCreating = false;

  final List<String> _ageGroups = ['kids', 'teens', 'adults'];
  final List<String> _avatars = [
    'assets/images/avatars/avatar-1.png',
    'assets/images/avatars/avatar-2.png',
    'assets/images/avatars/avatar-3.png',
    'assets/images/avatars/avatar-4.png',
    'assets/images/avatars/avatar-5.png',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1B3D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Name field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Profile Name',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF6A5ACD)),
                  borderRadius: BorderRadius.circular(8),
                ),
                fillColor: Colors.white.withOpacity(0.1),
                filled: true,
              ),
              maxLength: 20,
            ),

            const SizedBox(height: 16),

            // Age group selection
            Text(
              'Age Group',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _ageGroups.map((group) {
                final isSelected = _selectedAgeGroup == group;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedAgeGroup = group),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6A5ACD) : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6A5ACD) : Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        group.capitalize(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Avatar selection
            Text(
              'Choose Avatar',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _avatars.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = null),
                      child: Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedAvatar == null
                                ? const Color(0xFF6A5ACD)
                                : Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.white.withOpacity(0.7),
                          size: 30,
                        ),
                      ),
                    );
                  }

                  final avatarPath = _avatars[index - 1];
                  final isSelected = _selectedAvatar == avatarPath;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = avatarPath),
                    child: Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6A5ACD)
                              : Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: AssetImage(avatarPath),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isCreating ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A5ACD),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createProfile() async {
    if (_nameController.text.trim().isEmpty) {
      LogManager.logProfileValidation(_nameController.text.trim(), 'Empty profile name');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a profile name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final profileManager = ref.read(profileManagerProvider.notifier);
      final profile = await profileManager.createProfile(
        name: _nameController.text.trim(),
        avatar: _selectedAvatar,
        ageGroup: _selectedAgeGroup,
      );

      if (profile != null && mounted) {
        // Track analytics safely without breaking profile creation
        final analyticsManager = ref.read(profileAnalyticsManagerProvider.notifier);
        await analyticsManager.trackProfileCreated(
          profileId: profile.id,
          profileName: profile.name,
          ageGroup: _selectedAgeGroup,
          avatar: _selectedAvatar,
        );

        Navigator.pop(context);
        widget.onProfileCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile "${profile.name}" created successfully!'),
            backgroundColor: const Color(0xFF6A5ACD),
          ),
        );
      } else if (mounted) {
        LogManager.logProfileError('creation', 'Profile creation returned null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create profile. Name might already exist.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      LogManager.logProfileError('creation', e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
