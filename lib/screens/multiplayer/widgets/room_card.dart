import 'package:flutter/material.dart';

class RoomCard extends StatelessWidget {
  final String id;
  final String? name;
  final int? capacity;
  final int? players;
  final String? status;
  final String? gameMode;
  final VoidCallback? onTap;

  const RoomCard({
    super.key,
    required this.id,
    this.name,
    this.capacity,
    this.players,
    this.status,
    this.gameMode,
    this.onTap,
  });

  factory RoomCard.fromJson({
    required Map<String, dynamic> json,
    VoidCallback? onTap,
  }) {
    return RoomCard(
      id: (json['roomId'] ?? '').toString(),
      name: json['name']?.toString() ?? json['roomName']?.toString(),
      capacity: _asInt(json['maxPlayers'] ?? json['capacity']),
      players: _asInt(json['playerCount'] ??
          (json['players'] is List ? (json['players'] as List).length : null)),
      status: json['status']?.toString(),
      gameMode: json['gameMode']?.toString(),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusInfo = _getStatusInfo(status);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.meeting_room_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name ?? 'Room $id',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'ID: $id',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusInfo.$2.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusInfo.$2.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusInfo.$3,
                            size: 12,
                            color: statusInfo.$2,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusInfo.$1,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusInfo.$2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoItem(
                      icon: Icons.groups_rounded,
                      label: 'Players',
                      value: '${players ?? 0}/${capacity ?? 8}',
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoItem(
                      icon: Icons.gamepad_rounded,
                      label: 'Mode',
                      value: gameMode ?? 'Classic',
                      color: const Color(0xFF8B5CF6),
                      isDark: isDark,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF6366F1),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _getStatusInfo(String? status) {
    switch (status?.toLowerCase()) {
      case 'waiting':
        return ('Waiting', const Color(0xFF10B981), Icons.hourglass_empty_rounded);
      case 'in_game':
        return ('In Game', const Color(0xFFF59E0B), Icons.play_circle_rounded);
      case 'full':
        return ('Full', const Color(0xFFEF4444), Icons.block_rounded);
      default:
        return ('Available', const Color(0xFF10B981), Icons.check_circle_rounded);
    }
  }
}

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
