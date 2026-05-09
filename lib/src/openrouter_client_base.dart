import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/chat.dart';
import 'models/completion.dart';
import 'models/model_info.dart';
import 'openrouter_exception.dart';

/// A client for interacting with the OpenRouter API.
class OpenRouterClient {
  OpenRouterClient({
    /// Your OpenRouter API key. You can find this in your OpenRouter dashboard.
    required this.apiKey,

    /// Optional HTTP client. If not provided, a new instance will be created.
    http.Client? httpClient,

    /// Optional referer header value to include in requests.
    this.referer,

    /// Optional title header value to include in requests.
    this.title,
    Map<String, String>? additionalHeaders,
  })  : _http = httpClient ?? http.Client(),
        _additionalHeaders = additionalHeaders ?? const {};

  final String apiKey;
  final String? referer;
  final String? title;

  final http.Client _http;
  final Map<String, String> _additionalHeaders;

  Future<OpenRouterModelsResponse> listModels() async {
    final json = await _getJson('models');
    return OpenRouterModelsResponse.fromJson(json);
  }

  Future<ChatCompletionResponse> createChatCompletion(
    ChatCompletionRequest request,
  ) async {
    final json = await _postJson('chat/completions', request.toJson());
    return ChatCompletionResponse.fromJson(json);
  }

  Future<Map<String, dynamic>> createCompletion(
    CompletionRequest request,
  ) async {
    return _postJson('/completions', request.toJson());
  }

  void close() => _http.close();

  Uri _resolveUri(String path) {
    return Uri.parse('https://openrouter.ai/api/v1/$path');
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'openrouter_client',
      ..._additionalHeaders,
    };

    if (referer != null && referer!.isNotEmpty) {
      headers['HTTP-Referer'] = referer!;
    }
    if (title != null && title!.isNotEmpty) {
      headers['X-Title'] = title!;
    }

    return headers;
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _http.get(_resolveUri(path), headers: _headers());
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, Object?> payload,
  ) async {
    final response = await _http.post(
      _resolveUri(path),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.body;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage = _extractErrorMessage(body);
      final message = errorMessage ?? 'Request failed';
      final responseBody = _tryDecode(body);

      switch (response.statusCode) {
        case 400:
          throw OpenRouterBadRequestException(
            message,
            responseBody: responseBody,
          );
        case 401:
          throw OpenRouterAuthenticationException(
            message,
            responseBody: responseBody,
          );
        case 402:
          throw OpenRouterInsufficientCreditsException(
            message,
            responseBody: responseBody,
          );
        case 403:
          throw OpenRouterModerationException(
            message,
            responseBody: responseBody,
          );
        case 408:
          throw OpenRouterTimeoutException(
            message,
            responseBody: responseBody,
          );
        case 429:
          throw OpenRouterRateLimitException(
            message,
            responseBody: responseBody,
          );
        case 502:
          throw OpenRouterUpstreamException(
            message,
            responseBody: responseBody,
          );
        case 503:
          throw OpenRouterNoProviderException(
            message,
            responseBody: responseBody,
          );
        default:
          throw OpenRouterApiException(
            message,
            statusCode: response.statusCode,
            responseBody: responseBody,
          );
      }
    }

    final decoded = _tryDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw OpenRouterException('Unexpected response format.');
  }

  Object? _tryDecode(String body) {
    if (body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  String? _extractErrorMessage(String body) {
    final decoded = _tryDecode(body);

    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];

      if (error is Map<String, dynamic>) {
        final message = error['message'];

        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    }

    return null;
  }
}
