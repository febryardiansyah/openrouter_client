class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    this.name,
  });

  final String role;
  final Object content;
  final String? name;

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
