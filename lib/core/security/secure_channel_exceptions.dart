class SecureChannelException implements Exception {
  final String message;
  const SecureChannelException(this.message);

  @override
  String toString() => 'SecureChannelException: $message';
}

class SecureSessionExpiredException extends SecureChannelException {
  const SecureSessionExpiredException(super.message);
}

class SecureDecryptException extends SecureChannelException {
  const SecureDecryptException(super.message);
}
