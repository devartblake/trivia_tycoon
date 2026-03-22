import 'package:flutter/material.dart';

import '../../../core/services/settings/multi_profile_service.dart';
import '../enhanced/sheets/edit_profile_bottom_sheet.dart';

/// Username display row with edit button and info chips (age group, country, subject).
class ProfileUsernameSection extends StatelessWidget {
  const ProfileUsernameSection({super.key, required this.profile});

  final ProfileData profile;

  @override
  Widget build(BuildContext context) {
    final favoriteSubject = profile.preferences['favoriteSubject'] ?? 'Learning';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                profile.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showEditNameBottomSheet(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildInfoChip(
              icon: Icons.school_rounded,
              label: profile.ageGroup?.toUpperCase() ?? 'Student',
            ),
            if (profile.country != null)
              _buildInfoChip(
                icon: Icons.location_on_rounded,
                label: profile.country!,
              ),
            _buildInfoChip(
              icon: Icons.favorite_rounded,
              label: 'Loves $favoriteSubject',
              color: const Color(0xFFFBBF24),
            ),
          ],
        ),
      ],
    );
  }

  void _showEditNameBottomSheet(BuildContext context) {
    EditProfileBottomSheet.show(context, profile);
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color ?? Colors.white.withValues(alpha: 0.9),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
