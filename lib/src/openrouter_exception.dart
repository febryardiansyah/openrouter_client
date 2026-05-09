class OpenRouterException implements Exception {
  OpenRouterException(this.message);

  final String message;

  @override
  String toString() => 'OpenRouterException: $message';
}

class OpenRouterApiException extends OpenRouterException {
  OpenRouterApiException(
    super.message, {
    required this.statusCode,
    this.responseBody,
  });

  final int statusCode;
  final Object? responseBody;

  @override
  String toString() =>
      'OpenRouterApiException($statusCode): $message\n$responseBody';
}

class OpenRouterAuthenticationException extends OpenRouterApiException {
  OpenRouterAuthenticationException(super.message) : super(statusCode: 401);
}
