import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String userId;
  final String displayName;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final bool isOwnProfile;

  const ProfileHeader({
    super.key,
    required this.userId,
    required this.displayName,
    required this.username,
    this.bio,
    this.avatarUrl,
    this.isOwnProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(
                displayName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
                  : null,
            ),
            if (isOwnProfile)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          displayName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          username,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (bio != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              bio!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }
}
