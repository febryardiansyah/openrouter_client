import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/chat.dart';
import 'models/chat_stream.dart';
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

    /// Optional [HTTP-Referer] header value to include in requests.
    this.referer,

    /// Optional [X-Title] header value to include in requests.
    this.title,
    Map<String, String>? additionalHeaders,
  })  : _http = httpClient ?? http.Client(),
        _additionalHeaders = additionalHeaders ?? const {};

  final String apiKey;
  final String? referer;
  final String? title;

  final http.Client _http;
  final Map<String, String> _additionalHeaders;

  /// Retrieves a list of available models from the OpenRouter API.
  /// Returns an [OpenRouterModelsResponse] containing the list of models.
  Future<OpenRouterModelsResponse> listModels() async {
    final json = await _getJson('models');
    return OpenRouterModelsResponse.fromJson(json);
  }

  /// Creates a chat completion based on the provided [ChatCompletionRequest].
  /// Returns a [ChatCompletionResponse] containing the generated completion.
  Future<ChatCompletionResponse> createChatCompletion(
    ChatCompletionRequest request,
  ) async {
    final json = await _postJson('chat/completions', request.toJson());
    return ChatCompletionResponse.fromJson(json);
  }

  /// Creates a chat completion stream based on the provided [ChatCompletionRequest].
  /// Returns a stream of [ChatCompletionStreamResponse] objects as the completion is generated.
  Stream<ChatCompletionStreamResponse> streamChatCompletion(
    ChatCompletionRequest request,
  ) async* {
    final payload = <String, Object?>{
      ...request.toJson(),
      'stream': true,
    };

    final streamedResponse = await _http.send(
      http.Request('POST', _resolveUri('chat/completions'))
        ..headers.addAll(_headers())
        ..body = jsonEncode(payload),
    );

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      final body = await streamedResponse.stream.bytesToString();
      final errorResponse = http.Response(
        body,
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
      );
      _decodeResponse(errorResponse);
      return;
    }

    final lines = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (!line.startsWith('data:')) {
        continue;
      }

      final data = line.substring(5).trimLeft();
      if (data.isEmpty) {
        continue;
      }
      if (data == '[DONE]') {
        break;
      }

      final decoded = _tryDecode(data);
      if (decoded is Map<String, dynamic>) {
        yield ChatCompletionStreamResponse.fromJson(decoded);
      }
    }
  }

  /// Creates a completion based on the provided [CompletionRequest].
  Future<CompletionResponse> createCompletion(
    CompletionRequest request,
  ) async {
    final json = await _postJson('/completions', request.toJson());
    return CompletionResponse.fromJson(json);
  }

  /// Closes the underlying HTTP client. Should be called when the client is no longer needed.
  void close() => _http.close();

  /// Resolves a relative API path to a full URI.
  Uri _resolveUri(String path) {
    return Uri.parse('https://openrouter.ai/api/v1/$path');
  }

  /// Constructs the headers for API requests, including authorization and any additional headers.
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

  /// Helper method to perform a GET request and decode the JSON response.
  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _http.get(_resolveUri(path), headers: _headers());
    return _decodeResponse(response);
  }

  /// Helper method to perform a POST request with a JSON payload and decode the JSON response.
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

  /// Decodes the HTTP response, handling errors and extracting error messages when necessary.
  /// Returns the decoded JSON as a Map if the response is successful, or throws an appropriate exception if an error occurs.
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

  /// Tries to decode a JSON string, returning the decoded object or the original string if decoding fails.
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

  /// Extracts an error message from the response body if it follows the expected error format.
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
