class QrPayload {
  static String buildUri({
    required String code,
    required String ownerUserId,
    required int issuedAtUnix,
    String? signature, // optional
  }) {
    final qp = {
      'v': '1',
      'rc': code,
      'uid': ownerUserId,
      'ts': issuedAtUnix.toString(),
      if (signature != null) 'sig': signature,
    };
    final query = qp.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return 'tt://invite?$query';
  }
}
