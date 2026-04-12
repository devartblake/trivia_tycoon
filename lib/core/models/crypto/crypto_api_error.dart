import '../../services/api_service.dart';

class CryptoApiException implements Exception {
  const CryptoApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details = const <String, dynamic>{},
    this.path,
  });

  final String code;
  final String message;
  final int? statusCode;
  final Map<String, dynamic> details;
  final String? path;

  bool get isCryptoDisabled => code == 'CRYPTO_DISABLED';
  bool get isValidationError => code == 'VALIDATION_ERROR';
  bool get isMinWithdrawal => code == 'MIN_WITHDRAWAL';
  bool get isWalletNotLinked => code == 'WALLET_NOT_LINKED';
  bool get isInsufficientBalance => code == 'INSUFFICIENT_CRYPTO_BALANCE';
  bool get isInsufficientStakedBalance =>
      code == 'INSUFFICIENT_STAKED_BALANCE';

  factory CryptoApiException.fromApiRequestException(
    ApiRequestException exception,
  ) {
    return CryptoApiException(
      code: exception.errorCode ?? 'CRYPTO_REQUEST_FAILED',
      message: exception.message,
      statusCode: exception.statusCode,
      details: exception.details ?? const <String, dynamic>{},
      path: exception.path,
    );
  }

  @override
  String toString() {
    final status = statusCode == null ? '' : ' ($statusCode)';
    return 'CryptoApiException[$code]$status: $message';
  }
}
