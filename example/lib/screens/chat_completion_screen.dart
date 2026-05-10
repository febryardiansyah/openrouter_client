import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:openrouter_client/openrouter_client.dart';

import '../widgets/example_scaffold.dart';
import '../widgets/section_card.dart';
import '../widgets/status_banner.dart';

class ChatCompletionScreen extends StatefulWidget {
  const ChatCompletionScreen({super.key, required this.apiKey});

  final String apiKey;

  @override
  State<ChatCompletionScreen> createState() => _ChatCompletionScreenState();
}

class _ChatCompletionScreenState extends State<ChatCompletionScreen> {
  final _modelController = TextEditingController(text: 'openai/gpt-4o-mini');
  final _promptController = TextEditingController(
    text: 'Say hello from OpenRouter in one sentence.',
  );

  String? _responseText;
  String? _errorText;
  bool _sending = false;
  bool _useToolCalling = false;

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
      if (_useToolCalling) {
        await _sendPromptWithTools(
          client: client,
          modelId: modelId,
          prompt: prompt,
        );
      } else {
        final response = await client.createChatCompletion(
          ChatCompletionRequest(
            model: modelId,
            messages: [ChatMessage(role: 'user', content: prompt)],
            temperature: 0.7,
          ),
        );
        final message = response.choices.isNotEmpty
            ? response.choices.first.message
            : ChatMessage(role: 'assistant', content: 'No response choices.');
        setState(() {
          _responseText = message.content.toString();
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

  Future<void> _sendPromptWithTools({
    required OpenRouterClient client,
    required String modelId,
    required String prompt,
  }) async {
    final firstResponse = await client.createChatCompletion(
      ChatCompletionRequest(
        model: modelId,
        messages: [ChatMessage(role: 'user', content: prompt)],
        temperature: 0.7,
        tools: _toolDefinitions(),
      ),
    );
    final firstMessage = firstResponse.choices.isNotEmpty
        ? firstResponse.choices.first.message
        : ChatMessage(role: 'assistant', content: 'No response choices.');
    final toolCalls = firstMessage.toolCalls;

    if (toolCalls == null || toolCalls.isEmpty) {
      setState(() {
        _responseText = firstMessage.content.toString();
      });
      return;
    }

    final toolMessages = await _resolveToolCalls(toolCalls);
    final finalMessage = toolMessages.isNotEmpty
        ? toolMessages.first
        : ChatMessage(role: 'assistant', content: 'No response choices.');

    setState(() {
      _responseText = finalMessage.content.toString();
    });
  }

  List<ToolDefinition> _toolDefinitions() {
    return [
      ToolDefinition(
        function: ToolFunctionDefinition(
          name: 'say_hi',
          description: 'Return a friendly hello message.',
          parameters: {'type': 'object', 'properties': {}},
        ),
      ),
    ];
  }

  Future<List<ChatMessage>> _resolveToolCalls(List<ToolCall> toolCalls) async {
    final responses = <ChatMessage>[];

    for (final call in toolCalls) {
      final name = call.function?.name ?? '';

      if (name == 'say_hi') {
        final result = 'Hi! what do u want from me?';
        responses.add(
          ChatMessage(role: 'tool', content: result, toolCallId: call.id),
        );
      } else {
        responses.add(
          ChatMessage(
            role: 'tool',
            content: jsonEncode({'error': 'Unknown tool: $name'}),
            toolCallId: call.id,
          ),
        );
      }
    }

    return responses;
  }

  @override
  Widget build(BuildContext context) {
    return ExampleScaffold(
      title: 'Chat completion',
      child: Column(
        children: [
          SectionCard(
            title: 'Request',
            child: Column(
              children: [
                SwitchListTile(
                  value: _useToolCalling,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable tool calling'),
                  subtitle: const Text(
                    'Allow the model to request local tools.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _useToolCalling = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
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
                        label: Text(_sending ? 'Sending...' : 'Send prompt'),
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
