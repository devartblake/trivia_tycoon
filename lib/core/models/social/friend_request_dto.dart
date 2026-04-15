class FriendRequestDto {
  const FriendRequestDto({
    required this.requestId,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.status,
    required this.createdAtUtc,
    required this.respondedAtUtc,
    this.senderDisplayName,
    this.senderUsername,
    this.senderAvatarUrl,
  });

  final String requestId;
  final String fromPlayerId;
  final String toPlayerId;
  final String status;
  final DateTime? createdAtUtc;
  final DateTime? respondedAtUtc;
  final String? senderDisplayName;
  final String? senderUsername;
  final String? senderAvatarUrl;

  bool get isPending => status.toLowerCase() == 'pending';

  factory FriendRequestDto.fromJson(Map<String, dynamic> json) {
    return FriendRequestDto(
      requestId: json['requestId']?.toString() ?? '',
      fromPlayerId: json['fromPlayerId']?.toString() ?? '',
      toPlayerId: json['toPlayerId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      createdAtUtc: _parseDateTime(json['createdAtUtc']),
      respondedAtUtc: _parseDateTime(json['respondedAtUtc']),
      senderDisplayName: json['senderDisplayName']?.toString(),
      senderUsername: json['senderUsername']?.toString(),
      senderAvatarUrl: json['senderAvatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'fromPlayerId': fromPlayerId,
      'toPlayerId': toPlayerId,
      'status': status,
      'createdAtUtc': createdAtUtc?.toIso8601String(),
      'respondedAtUtc': respondedAtUtc?.toIso8601String(),
      'senderDisplayName': senderDisplayName,
      'senderUsername': senderUsername,
      'senderAvatarUrl': senderAvatarUrl,
    };
  }

  static DateTime? _parseDateTime(Object? value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}
