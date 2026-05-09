import 'chat.dart';
import 'tools.dart';

class ChatCompletionStreamDelta {
  ChatCompletionStreamDelta({
    this.role,
    this.content,
    this.name,
    this.toolCalls,
  });

  final String? role;
  final Object? content;
  final String? name;
  final List<ToolCall>? toolCalls;

  factory ChatCompletionStreamDelta.fromJson(Map<String, dynamic> json) {
    final toolCallsJson = json['tool_calls'];

    return ChatCompletionStreamDelta(
      role: json['role'] as String?,
      content: json['content'],
      name: json['name'] as String?,
      toolCalls: toolCallsJson is List
          ? toolCallsJson
              .whereType<Map<String, dynamic>>()
              .map(ToolCall.fromJson)
              .toList()
          : null,
    );
  }
}

class ChatCompletionStreamChoice {
  ChatCompletionStreamChoice({
    required this.delta,
    this.index,
    this.finishReason,
  });

  final ChatCompletionStreamDelta delta;
  final int? index;
  final String? finishReason;

  factory ChatCompletionStreamChoice.fromJson(Map<String, dynamic> json) {
    final deltaJson = json['delta'];
    final delta = deltaJson is Map<String, dynamic>
        ? ChatCompletionStreamDelta.fromJson(deltaJson)
        : ChatCompletionStreamDelta();

    return ChatCompletionStreamChoice(
      delta: delta,
      index: _parseInt(json['index']),
      finishReason: json['finish_reason'] as String?,
    );
  }
}

class ChatCompletionStreamResponse {
  ChatCompletionStreamResponse({
    required this.id,
    required this.choices,
    this.object,
    this.created,
    this.model,
    this.usage,
  });

  final String id;
  final String? object;
  final int? created;
  final String? model;
  final List<ChatCompletionStreamChoice> choices;
  final ChatCompletionUsage? usage;

  factory ChatCompletionStreamResponse.fromJson(Map<String, dynamic> json) {
    final choices = (json['choices'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ChatCompletionStreamChoice.fromJson)
        .toList();

    final usageJson = json['usage'];

    return ChatCompletionStreamResponse(
      id: json['id'] as String? ?? '',
      object: json['object'] as String?,
      created: _parseInt(json['created']),
      model: json['model'] as String?,
      choices: choices,
      usage: usageJson is Map<String, dynamic>
          ? ChatCompletionUsage.fromJson(usageJson)
          : null,
    );
  }
}

int? _parseInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}
