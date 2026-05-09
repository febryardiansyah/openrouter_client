import 'package:flutter/material.dart';
import 'package:openrouter_client/openrouter_client.dart';

void main() {
  runApp(const OpenRouterExampleApp());
}

class OpenRouterExampleApp extends StatelessWidget {
  const OpenRouterExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1F6FEB);
    return MaterialApp(
      title: 'OpenRouter Client Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        fontFamily: 'Avenir',
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF3F6FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      home: const OpenRouterDemoPage(),
    );
  }
}

class OpenRouterDemoPage extends StatefulWidget {
  const OpenRouterDemoPage({super.key});

  @override
  State<OpenRouterDemoPage> createState() => _OpenRouterDemoPageState();
}

class _OpenRouterDemoPageState extends State<OpenRouterDemoPage> {
  final _apiKeyController = TextEditingController();
  final _promptController = TextEditingController(
    text: 'Say hello from OpenRouter in one sentence.',
  );

  String? _responseText;
  String? _errorText;
  bool _sending = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  OpenRouterClient _createClient() {
    return OpenRouterClient(apiKey: _apiKeyController.text.trim());
  }

  Future<void> _sendPrompt() async {
    final apiKey = _apiKeyController.text.trim();
    final modelId = 'openai/gpt-4o-mini';
    final prompt = _promptController.text.trim();

    if (apiKey.isEmpty) {
      setState(() {
        _errorText = 'Enter your OpenRouter API key first.';
      });
      return;
    }
    if (prompt.isEmpty) {
      setState(() {
        _errorText = 'Add a prompt to send.';
      });
      return;
    }
    if (modelId.isEmpty) {
      setState(() {
        _errorText = 'Enter a model id first.';
      });
      return;
    }

    setState(() {
      _sending = true;
      _errorText = null;
      _responseText = null;
    });

    final client = _createClient();
    final buffer = StringBuffer();
    try {
      await for (final chunk in client.streamChatCompletion(
        ChatCompletionRequest(
          model: modelId,
          messages: [ChatMessage(role: 'user', content: prompt)],
          temperature: 0.7,
        ),
      )) {
        final delta = _extractStreamDelta(chunk);
        if (delta.isEmpty) {
          continue;
        }

        buffer.write(delta);
        if (mounted) {
          setState(() {
            _responseText = buffer.toString();
          });
        }
      }

      if (buffer.isEmpty && mounted) {
        setState(() {
          _responseText = 'No response choices.';
        });
      }
    } on OpenRouterApiException catch (error) {
      setState(() {
        _errorText = error.message;
      });
    } catch (error) {
      setState(() {
        _errorText = 'Request failed: $error';
      });
    } finally {
      client.close();
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  String _extractStreamDelta(ChatCompletionStreamResponse response) {
    if (response.choices.isEmpty) {
      return '';
    }

    final content = response.choices.first.delta.content;
    if (content == null) {
      return '';
    }
    if (content is String) {
      return content;
    }

    return content.toString();
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
                          'Enter a model id and send a prompt.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        _SectionCard(
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
                        _SectionCard(
                          title: 'Prompt',
                          child: Column(
                            children: [
                              TextField(
                                controller: _promptController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Message',
                                  hintText: 'Ask the model something...',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _sending ? null : _sendPrompt,
                                      icon: _sending
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.send),
                                      label: Text(
                                        _sending ? 'Sending...' : 'Send prompt',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 20),
                          _StatusBanner(
                            text: _errorText!,
                            backgroundColor: const Color(0xFFFFE2E2),
                            textColor: const Color(0xFF7A1C1C),
                          ),
                        ],
                        if (_responseText != null) ...[
                          const SizedBox(height: 20),
                          _SectionCard(
                            title: 'Response',
                            child: Text(
                              _responseText!,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(height: 1.4),
                            ),
                          ),
                        ],
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E6EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
