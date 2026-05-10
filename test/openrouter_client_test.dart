import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openrouter_client/openrouter_client.dart';
import 'package:test/test.dart';

void main() {
  final baseUrl = 'https://openrouter.ai/api/v1';
  final errorPayload = {
    'error': {'message': 'Bad key'},
  };

  group('OpenRouterClient success responses', () {
    test('listModels returns decoded models', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), '$baseUrl/models');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'test-model',
                'name': 'Test Model',
                'context_length': 8192,
                'description': 'Example model',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = OpenRouterClient(apiKey: 'token', httpClient: client);
      final response = await api.listModels();

      expect(response.data, hasLength(1));
      expect(response.data.first.id, 'test-model');
      expect(response.data.first.contextLength, 8192);
    });

    test('createChatCompletion sends headers and parses response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), '$baseUrl/chat/completions');
        expect(request.headers['authorization'], 'Bearer token');
        expect(request.headers['http-referer'], 'https://example.dev');
        expect(request.headers['x-title'], 'Test App');
        expect(request.headers['content-type'], 'application/json');
        expect(request.headers['accept'], 'application/json');

        return http.Response(
          jsonEncode({
            'id': 'chat-1',
            'choices': [
              {
                'index': 0,
                'finish_reason': 'stop',
                'message': {'role': 'assistant', 'content': 'Hello!'},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = OpenRouterClient(
        apiKey: 'token',
        referer: 'https://example.dev',
        title: 'Test App',
        httpClient: client,
      );

      final response = await api.createChatCompletion(
        ChatCompletionRequest(
          model: 'test-model',
          messages: [ChatMessage(role: 'user', content: 'Hello')],
        ),
      );

      expect(response, isA<ChatCompletionResponse>());
      expect(response.id, 'chat-1');
      expect(response.choices.first.message.content, 'Hello!');
    });

    test('streamChatCompletion yields streamed chunks', () async {
      final client = MockClient.streaming((request, bodyStream) async {
        final bodyBytes = await bodyStream.toBytes();
        final payload =
            jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;
        expect(payload['stream'], isTrue);
        expect(request.url.toString(), '$baseUrl/chat/completions');

        final chunks = [
          'data: {"id":"chunk-1","choices":[{"delta":{"role":"assistant","content":"Hi"}}]}',
          'data: {"id":"chunk-1","choices":[{"delta":{"content":" there"}}]}',
          'data: [DONE]',
        ].join('\n');

        final stream = Stream<List<int>>.value(utf8.encode(chunks));
        return http.StreamedResponse(
          stream,
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });

      final api = OpenRouterClient(apiKey: 'token', httpClient: client);
      final responses = await api
          .streamChatCompletion(
            ChatCompletionRequest(
              model: 'test-model',
              messages: [ChatMessage(role: 'user', content: 'Hello')],
            ),
          )
          .toList();

      expect(responses, hasLength(2));
      expect(responses.first.choices.first.delta.content, 'Hi');
      expect(responses.last.choices.first.delta.content, ' there');
    });
  });

  group('OpenRouterClient exception responses', () {
    test('createChatCompletion throws authentication error', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(errorPayload),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = OpenRouterClient(apiKey: 'token', httpClient: client);

      expect(
        () => api.createChatCompletion(
          ChatCompletionRequest(
            model: 'test-model',
            messages: [ChatMessage(role: 'user', content: 'Hello')],
          ),
        ),
        throwsA(
          isA<OpenRouterAuthenticationException>().having(
            (error) => error.message,
            'message',
            'Bad key',
          ),
        ),
      );
    });

    test('createChatCompletion throws bad request error', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(errorPayload),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = OpenRouterClient(apiKey: 'token', httpClient: client);

      await expectLater(
        api.createChatCompletion(
          ChatCompletionRequest(
            model: 'test-model',
            messages: [ChatMessage(role: 'user', content: 'Hello')],
          ),
        ),
        throwsA(
          isA<OpenRouterBadRequestException>().having(
            (error) => error.message,
            'message',
            'Bad key',
          ),
        ),
      );
    });

    test('createChatCompletion throws insufficient credits error', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(errorPayload),
          402,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = OpenRouterClient(apiKey: 'token', httpClient: client);

      await expectLater(
        api.createChatCompletion(
          ChatCompletionRequest(
            model: 'test-model',
            messages: [ChatMessage(role: 'user', content: 'Hello')],
          ),
        ),
        throwsA(
          isA<OpenRouterInsufficientCreditsException>().having(
            (error) => error.message,
            'message',
            'Bad key',
          ),
        ),
      );
    });

    test('createChatCompletion throws moderation error', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(errorPayload),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = OpenRouterClient(apiKey: 'token', httpClient: client);

      await expectLater(
        api.createChatCompletion(
          ChatCompletionRequest(
            model: 'test-model',
            messages: [ChatMessage(role: 'user', content: 'Hello')],
          ),
        ),
        throwsA(
          isA<OpenRouterModerationException>().having(
            (error) => error.message,
            'message',
            'Bad key',
          ),
        ),
      );
    });

    test('createChatCompletion throws timeout error', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(errorPayload),
          408,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = OpenRouterClient(apiKey: 'token', httpClient: client);

      await expectLater(
        api.createChatCompletion(
          ChatCompletionRequest(
            model: 'test-model',
            messages: [ChatMessage(role: 'user', content: 'Hello')],
          ),
        ),
        throwsA(
          isA<OpenRouterTimeoutException>().having(
            (error) => error.message,
            'message',
            'Bad key',
          ),
        ),
      );
    });

    test('createChatCompletion throws rate limit error', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(errorPayload),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = OpenRouterClient(apiKey: 'token', httpClient: client);

      await expectLater(
        api.createChatCompletion(
          ChatCompletionRequest(
            model: 'test-model',
            messages: [ChatMessage(role: 'user', content: 'Hello')],
          ),
        ),
        throwsA(
          isA<OpenRouterRateLimitException>().having(
            (error) => error.message,
            'message',
            'Bad key',
          ),
        ),
      );
    });

    test('createChatCompletion throws upstream error', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(errorPayload),
          502,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = OpenRouterClient(apiKey: 'token', httpClient: client);

      await expectLater(
        api.createChatCompletion(
          ChatCompletionRequest(
            model: 'test-model',
            messages: [ChatMessage(role: 'user', content: 'Hello')],
          ),
        ),
        throwsA(
          isA<OpenRouterUpstreamException>().having(
            (error) => error.message,
            'message',
            'Bad key',
          ),
        ),
      );
    });

    test('createChatCompletion throws no provider error', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(errorPayload),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = OpenRouterClient(apiKey: 'token', httpClient: client);

      await expectLater(
        api.createChatCompletion(
          ChatCompletionRequest(
            model: 'test-model',
            messages: [ChatMessage(role: 'user', content: 'Hello')],
          ),
        ),
        throwsA(
          isA<OpenRouterNoProviderException>().having(
            (error) => error.message,
            'message',
            'Bad key',
          ),
        ),
      );
    });

    test('createChatCompletion throws generic api error', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(errorPayload),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = OpenRouterClient(apiKey: 'token', httpClient: client);

      await expectLater(
        api.createChatCompletion(
          ChatCompletionRequest(
            model: 'test-model',
            messages: [ChatMessage(role: 'user', content: 'Hello')],
          ),
        ),
        throwsA(
          isA<OpenRouterApiException>()
              .having((error) => error.statusCode, 'statusCode', 500)
              .having((error) => error.message, 'message', 'Bad key'),
        ),
      );
    });
  });
}
