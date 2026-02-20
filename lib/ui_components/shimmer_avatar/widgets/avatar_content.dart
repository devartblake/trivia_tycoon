import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Avatar content widget that handles image loading and fallback
class AvatarContent extends StatelessWidget {
  final String? avatarPath;
  final double radius;
  final bool isLoading;

  const AvatarContent({
    super.key,
    required this.avatarPath,
    required this.radius,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildShimmerEffect();
    }

    if (avatarPath != null && avatarPath!.isNotEmpty) {
      if (avatarPath!.startsWith('assets/')) {
        return _buildAssetImage();
      } else if (avatarPath!.startsWith('http')) {
        return _buildNetworkImage();
      } else {
        return _buildFileImage();
      }
    }

    return _buildFallbackAvatar();
  }

  Widget _buildAssetImage() {
    return Image.asset(
      avatarPath!,
      fit: BoxFit.cover,
      width: radius * 2,
      height: radius * 2,
      errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
    );
  }

  Widget _buildNetworkImage() {
    return Image.network(
      avatarPath!,
      fit: BoxFit.cover,
      width: radius * 2,
      height: radius * 2,
      errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildShimmerEffect();
      },
    );
  }

  Widget _buildFileImage() {
    return Image.file(
      File(avatarPath!),
      fit: BoxFit.cover,
      width: radius * 2,
      height: radius * 2,
      errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.8),
            const Color(0xFF8B5CF6).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: radius * 1.0,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFF9FAFB),
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE5E7EB),
        ),
      ),
    );
  }
}
