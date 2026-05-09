# OpenRouter Client

A Dart client library for the OpenRouter API.

## Features

- List available models.
- Create chat completions.
- Create text completions.
- Pass through extra OpenRouter parameters as needed.

## Getting started

Add the dependency to your pubspec:

```yaml
dependencies:
	openrouter_client: ^0.1.0
```

## Usage

```dart
import 'package:openrouter_client/openrouter_client.dart';

Future<void> main() async {
	final client = OpenRouterClient(
		apiKey: 'YOUR_API_KEY',
		referer: 'https://your-app.example',
		title: 'Your App Name',
	);

	final models = await client.listModels();
	final firstModel = models.data.first.id;

	final response = await client.createChatCompletion(
		ChatCompletionRequest(
			model: firstModel,
			messages: [
				ChatMessage(role: 'user', content: 'Say hello from OpenRouter'),
			],
			temperature: 0.7,
		),
	);

	print(response);
	client.close();
}
```

## Additional information

- OpenRouter API docs: https://openrouter.ai/docs
- Contributions and issues are welcome.
