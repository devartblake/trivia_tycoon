import 'dart:io';
import 'package:flutter/material.dart';
import '../../../game/models/avatar_package_models.dart';

/// Enhanced Avatar Image Card - Using AvatarAssetRef (Preferred)
///
/// This version uses the type-safe AvatarAssetRef approach from AvatarAssetLoader.
/// No path guessing needed - the ref tells us exactly how to load it!
class AvatarImageCard extends StatelessWidget {
  final AvatarAssetRef avatarRef;
  final VoidCallback? onTap;
  final bool isSelected;

  const AvatarImageCard({
    super.key,
    required this.avatarRef,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Use the source type from the ref - no guessing!
    switch (avatarRef.source) {
      case AvatarSource.asset:
        // Bundled asset
        return Image.asset(
          avatarRef.path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        );

      case AvatarSource.file:
        // File from installed package
        return Image.file(
          File(avatarRef.path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        );

      case AvatarSource.network:
        // Network URL (if you add this later)
        return Image.network(
          avatarRef.path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingWidget();
          },
        );
      case AvatarSource.remote:
        // Treat remote references like network URLs to avoid runtime crashes.
        return Image.network(
          avatarRef.path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingWidget();
          },
        );
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1)),
        ),
      ),
    );
  }
}
