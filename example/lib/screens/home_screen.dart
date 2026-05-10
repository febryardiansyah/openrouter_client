import 'package:flutter/material.dart';

import '../widgets/section_card.dart';
import 'chat_completion_screen.dart';
import 'models_screen.dart';
import 'stream_chat_completion_screen.dart';

class OpenRouterHomePage extends StatefulWidget {
  const OpenRouterHomePage({super.key});

  @override
  State<OpenRouterHomePage> createState() => _OpenRouterHomePageState();
}

class _OpenRouterHomePageState extends State<OpenRouterHomePage> {
  final _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _openExample(Widget page) {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your OpenRouter API key first.')),
      );
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF6F4EF), Color(0xFFE7EEF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 720
                  ? 720.0
                  : constraints.maxWidth;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OpenRouter Client Demo',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your API key and pick a function to try.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        SectionCard(
                          title: 'Credentials',
                          child: Column(
                            children: [
                              TextField(
                                controller: _apiKeyController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'OpenRouter API key',
                                  hintText: 'sk-or-...',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SectionCard(
                          title: 'Examples',
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openExample(
                                        ModelsScreen(
                                          apiKey: _apiKeyController.text.trim(),
                                        ),
                                      ),
                                      icon: const Icon(Icons.list_alt),
                                      label: const Text('List models'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openExample(
                                        ChatCompletionScreen(
                                          apiKey: _apiKeyController.text.trim(),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.chat_bubble_outline,
                                      ),
                                      label: const Text('Chat completion'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openExample(
                                        StreamChatCompletionScreen(
                                          apiKey: _apiKeyController.text.trim(),
                                        ),
                                      ),
                                      icon: const Icon(Icons.auto_awesome),
                                      label: const Text(
                                        'Stream chat completion',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Tip: keep your API key in a safe place.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
