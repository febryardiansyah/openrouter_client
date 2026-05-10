import 'package:flutter/material.dart';
import 'package:openrouter_client/openrouter_client.dart';

import '../widgets/example_scaffold.dart';
import '../widgets/section_card.dart';
import '../widgets/status_banner.dart';

class StreamChatCompletionScreen extends StatefulWidget {
  const StreamChatCompletionScreen({super.key, required this.apiKey});

  final String apiKey;

  @override
  State<StreamChatCompletionScreen> createState() =>
      _StreamChatCompletionScreenState();
}

class _StreamChatCompletionScreenState
    extends State<StreamChatCompletionScreen> {
  final _modelController = TextEditingController(text: 'openai/gpt-4o-mini');
  final _promptController = TextEditingController(
    text: 'Say hello from OpenRouter in one sentence.',
  );

  String? _responseText;
  String? _errorText;
  bool _sending = false;

  @override
  void dispose() {
    _modelController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _sendPrompt() async {
    final modelId = _modelController.text.trim();
    final prompt = _promptController.text.trim();

    if (modelId.isEmpty || prompt.isEmpty) {
      setState(() {
        _errorText = 'Enter a model id and prompt.';
      });
      return;
    }

    setState(() {
      _sending = true;
      _errorText = null;
      _responseText = null;
    });

    final client = OpenRouterClient(apiKey: widget.apiKey);
    try {
      final buffer = StringBuffer();
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
    return ExampleScaffold(
      title: 'Stream chat completion',
      child: Column(
        children: [
          SectionCard(
            title: 'Request',
            child: Column(
              children: [
                TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model id',
                  ),
                ),
                const SizedBox(height: 12),
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
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(_sending ? 'Streaming...' : 'Start stream'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 16),
            StatusBanner(
              text: _errorText!,
              backgroundColor: const Color(0xFFFFE2E2),
              textColor: const Color(0xFF7A1C1C),
            ),
          ],
          if (_responseText != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Response',
              child: Text(
                _responseText!,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
