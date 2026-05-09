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

class OpenRouterBadRequestException extends OpenRouterApiException {
  OpenRouterBadRequestException(
    super.message, {
    super.responseBody,
  }) : super(statusCode: 400);
}

class OpenRouterAuthenticationException extends OpenRouterApiException {
  OpenRouterAuthenticationException(
    super.message, {
    super.responseBody,
  }) : super(statusCode: 401);
}

class OpenRouterInsufficientCreditsException extends OpenRouterApiException {
  OpenRouterInsufficientCreditsException(
    super.message, {
    super.responseBody,
  }) : super(statusCode: 402);
}

class OpenRouterModerationException extends OpenRouterApiException {
  OpenRouterModerationException(
    super.message, {
    super.responseBody,
  }) : super(statusCode: 403);
}

class OpenRouterTimeoutException extends OpenRouterApiException {
  OpenRouterTimeoutException(
    super.message, {
    super.responseBody,
  }) : super(statusCode: 408);
}

class OpenRouterRateLimitException extends OpenRouterApiException {
  OpenRouterRateLimitException(
    super.message, {
    super.responseBody,
  }) : super(statusCode: 429);
}

class OpenRouterUpstreamException extends OpenRouterApiException {
  OpenRouterUpstreamException(
    super.message, {
    super.responseBody,
  }) : super(statusCode: 502);
}

class OpenRouterNoProviderException extends OpenRouterApiException {
  OpenRouterNoProviderException(
    super.message, {
    super.responseBody,
  }) : super(statusCode: 503);
}
