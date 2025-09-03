import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerAvatar extends StatelessWidget {
  final double radius;
  final String? avatarPath;
  final String? initials;
  final String? ageGroup;
  final String? gender;
  final bool isLoading;
  final double xpProgress; // New XP progress field (0.0 to 1.0)
  final String status;  // 'online', 'offline', 'in game'

  const ShimmerAvatar({
    super.key,
    this.radius = 24,
    this.avatarPath,
    this.initials,
    this.ageGroup,
    this.gender,
    this.isLoading = false,
    this.xpProgress = 0.0,
    this.status = 'offline'
  });

  String _getFallbackAsset() {
    if (gender == 'male') {
      if (ageGroup == 'kids') return 'assets/images/avatars/male_kid.png';
      if (ageGroup == 'teens') return 'assets/images/avatars/male_teen.png';
      return 'assets/images/avatars/male_adult.png';
    } else if (gender == 'female') {
      if (ageGroup == 'kids') return 'assets/images/avatars/female_kid.png';
      if (ageGroup == 'teens') return 'assets/images/avatars/female_teen.png';
      return 'assets/images/avatars/female_adult.png';
    }
    return 'assets/images/avatars/default-avatar.png';
  }

  Color _getXPColor() {
    if (xpProgress >= 0.8) return Colors.green;
    if (xpProgress >= 0.5) return Colors.orange;
    return Colors.redAccent;
  }

  Color _getStatusColor() {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'in game':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = isLoading
        ? Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CircleAvatar(radius: radius, backgroundColor: Colors.grey[300]),
    )
        : _buildAvatar();

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: radius * 2 + 6,
          height: radius * 2 + 6,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: xpProgress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return CircularProgressIndicator(
                value: value,
                strokeWidth: 4,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(_getXPColor()),
              );
            },
          ),
        ),

        // Main avatar + status dot
        Stack(
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor: Colors.white,
              child: ClipOval(child: avatar),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: CircleAvatar(
                radius: 6,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 4.5,
                  backgroundColor: _getStatusColor(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    if (avatarPath != null && avatarPath!.isNotEmpty) {
      return Image.network(
        avatarPath!,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    if (initials != null && initials!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[400],
        child: Text(
          initials!,
          style: TextStyle(fontSize: radius * 0.6, color: Colors.white),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundImage: AssetImage(_getFallbackAsset()),
    );
  }
}
