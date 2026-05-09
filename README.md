# OpenRouter Client

A Dart client library for the OpenRouter API.

## Features

- List available models.
- Create chat completions.
- Stream chat completions.
- Create text completions.
- Tool/function calling via tools.
- Pass through extra OpenRouter parameters as needed.

## Getting started

Add the dependency to your pubspec:

```yaml
dependencies:
	openrouter_client: ^0.1.0
```

## Usage

Create the client once and reuse it across calls:

```dart
import 'package:openrouter_client/openrouter_client.dart';

final client = OpenRouterClient(apiKey: 'YOUR_API_KEY');
```

### List models

```dart
final models = await client.listModels();
final firstModel = models.data.first.id;
print(firstModel);
```

### Chat completion

```dart
final response = await client.createChatCompletion(
	ChatCompletionRequest(
		model: 'openai/gpt-4o-mini',
		messages: [
			ChatMessage(role: 'user', content: 'Say hello from OpenRouter'),
		],
		temperature: 0.7,
	),
);

print(response);
```

### Chat completion stream

```dart
final stream = client.streamChatCompletion(
	ChatCompletionRequest(
		model: 'openai/gpt-4o-mini',
		messages: [
			ChatMessage(role: 'user', content: 'Write a short poem about rain.'),
		],
	),
);

await for (final chunk in stream) {
	final delta = chunk.choices.first.delta.content;
	if (delta != null) {
		print(delta);
	}
}
```

### Text completion

```dart
final response = await client.createCompletion(
	CompletionRequest(
		model: 'openai/gpt-3.5-turbo-instruct',
		prompt: 'Write a tagline for a coffee shop.',
		maxTokens: 32,
	),
);

print(response.choices.first.text);
```

### Tools (function calling)

```dart
final response = await client.createChatCompletion(
	ChatCompletionRequest(
		model: 'openai/gpt-4o-mini',
		messages: [
			ChatMessage(role: 'user', content: 'What is the weather in Tokyo?'),
		],
		tools: [
			ToolDefinition(
				function: ToolFunctionDefinition(
					name: 'get_weather',
					description: 'Get weather by city name',
					parameters: {
						'type': 'object',
						'properties': {
							'city': {'type': 'string'},
						},
						'required': ['city'],
					},
				),
			),
		],
		toolChoice: ToolChoice.auto(),
	),
);

final toolCalls = response.choices.first.message.toolCalls ?? [];
for (final call in toolCalls) {
	print(call.function?.name);
	print(call.function?.arguments);
}
```

### Extra parameters

```dart
final response = await client.createChatCompletion(
	ChatCompletionRequest(
		model: 'openai/gpt-4o-mini',
		messages: [
			ChatMessage(role: 'user', content: 'Give me one fun fact about space.'),
		],
		extra: {
			'parallel_tool_calls': true,
			'max_completion_tokens': 64,
		},
	),
);

print(response.choices.first.message.content);
```

## Additional information

- OpenRouter API docs: https://openrouter.ai/docs
- Contributions and issues are welcome.
