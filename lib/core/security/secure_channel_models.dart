class SecureSession {
  final String sessionId;
  final String protocolVersion;
  final String selectedSuite;
  final List<int> clientToServerKey;
  final List<int> serverToClientKey;
  final DateTime expiresAtUtc;
  final int nextSequence;

  const SecureSession({
    required this.sessionId,
    required this.protocolVersion,
    required this.selectedSuite,
    required this.clientToServerKey,
    required this.serverToClientKey,
    required this.expiresAtUtc,
    this.nextSequence = 1,
  });

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAtUtc);

  SecureSession copyWith({
    int? nextSequence,
    DateTime? expiresAtUtc,
  }) {
    return SecureSession(
      sessionId: sessionId,
      protocolVersion: protocolVersion,
      selectedSuite: selectedSuite,
      clientToServerKey: clientToServerKey,
      serverToClientKey: serverToClientKey,
      expiresAtUtc: expiresAtUtc ?? this.expiresAtUtc,
      nextSequence: nextSequence ?? this.nextSequence,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'protocolVersion': protocolVersion,
        'selectedSuite': selectedSuite,
        'clientToServerKey': clientToServerKey,
        'serverToClientKey': serverToClientKey,
        'expiresAtUtc': expiresAtUtc.toIso8601String(),
        'nextSequence': nextSequence,
      };

  factory SecureSession.fromJson(Map<String, dynamic> json) => SecureSession(
        sessionId: json['sessionId']?.toString() ?? '',
        protocolVersion: json['protocolVersion']?.toString() ?? 'syn-sec-v1',
        selectedSuite:
            json['selectedSuite']?.toString() ?? 'X25519-HKDF-SHA256-AES256GCM',
        clientToServerKey:
            (json['clientToServerKey'] as List? ?? const []).cast<int>(),
        serverToClientKey:
            (json['serverToClientKey'] as List? ?? const []).cast<int>(),
        expiresAtUtc: DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '')
                ?.toUtc() ??
            DateTime.now().toUtc(),
        nextSequence: (json['nextSequence'] as num?)?.toInt() ?? 1,
      );
}

class EncryptedPayload {
  final String ciphertext;
  final String nonce;
  final String mac;
  final String contentType;
  final String encryptedAtUtc;

  const EncryptedPayload({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
    required this.contentType,
    required this.encryptedAtUtc,
  });

  Map<String, dynamic> toJson() => {
        'ciphertext': ciphertext,
        'nonce': nonce,
        'mac': mac,
        'contentType': contentType,
        'encryptedAtUtc': encryptedAtUtc,
      };

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) =>
      EncryptedPayload(
        ciphertext: json['ciphertext']?.toString() ?? '',
        nonce: json['nonce']?.toString() ?? '',
        mac: json['mac']?.toString() ?? '',
        contentType: json['contentType']?.toString() ?? 'application/json',
        encryptedAtUtc: json['encryptedAtUtc']?.toString() ??
            DateTime.now().toUtc().toIso8601String(),
      );
}
