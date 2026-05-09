import 'package:openrouter_client/openrouter_client.dart';
import 'package:test/test.dart';

void main() {
	test('chat completion request serializes', () {
		final request = ChatCompletionRequest(
			model: 'test-model',
			messages: [
				ChatMessage(role: 'user', content: 'Hello'),
			],
			temperature: 0.4,
			maxTokens: 10,
		);

		final json = request.toJson();
		expect(json['model'], 'test-model');
		expect(json['messages'], isA<List<Object?>>());
		expect(json['temperature'], 0.4);
		expect(json['max_tokens'], 10);
	});
}
