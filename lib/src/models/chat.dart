class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    this.name,
  });

  final String role;
  final Object content;
  final String? name;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String? ?? '',
      content: json['content'] ?? '',
      name: json['name'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'role': role,
      'content': content,
    };

    if (name != null && name!.isNotEmpty) {
      json['name'] = name;
    }

    return json;
  }
}

class ChatCompletionRequest {
  ChatCompletionRequest({
    required this.model,
    required this.messages,
    this.temperature,
    this.maxTokens,
    this.topP,
    this.stream,
    this.extra,
  });

  final String model;
  final List<ChatMessage> messages;
  final double? temperature;
  final int? maxTokens;
  final double? topP;
  final bool? stream;
  final Map<String, Object?>? extra;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'model': model,
      'messages': messages.map((message) => message.toJson()).toList(),
    };

    if (temperature != null) {
      json['temperature'] = temperature;
    }
    if (maxTokens != null) {
      json['max_tokens'] = maxTokens;
    }
    if (topP != null) {
      json['top_p'] = topP;
    }
    if (stream != null) {
      json['stream'] = stream;
    }

    if (extra != null && extra!.isNotEmpty) {
      json.addAll(extra!);
    }

    return json;
  }
}

class ChatCompletionUsage {
  ChatCompletionUsage({
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  });

  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  factory ChatCompletionUsage.fromJson(Map<String, dynamic> json) {
    return ChatCompletionUsage(
      promptTokens: _parseInt(json['prompt_tokens']),
      completionTokens: _parseInt(json['completion_tokens']),
      totalTokens: _parseInt(json['total_tokens']),
    );
  }
}

class ChatCompletionChoice {
  ChatCompletionChoice({
    required this.message,
    this.index,
    this.finishReason,
  });

  final ChatMessage message;
  final int? index;
  final String? finishReason;

  factory ChatCompletionChoice.fromJson(Map<String, dynamic> json) {
    final messageJson = json['message'];
    final message = messageJson is Map<String, dynamic>
        ? ChatMessage.fromJson(messageJson)
        : ChatMessage(role: 'assistant', content: '');

    return ChatCompletionChoice(
      message: message,
      index: _parseInt(json['index']),
      finishReason: json['finish_reason'] as String?,
    );
  }
}

class ChatCompletionResponse {
  ChatCompletionResponse({
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
  final List<ChatCompletionChoice> choices;
  final ChatCompletionUsage? usage;

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    final choices = (json['choices'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ChatCompletionChoice.fromJson)
        .toList();

    final usageJson = json['usage'];

    return ChatCompletionResponse(
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
