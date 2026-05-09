class CompletionRequest {
  CompletionRequest({
    required this.model,
    required this.prompt,
    this.temperature,
    this.maxTokens,
    this.topP,
    this.stream,
    this.extra,
  });

  final String model;
  final Object prompt;
  final double? temperature;
  final int? maxTokens;
  final double? topP;
  final bool? stream;
  final Map<String, Object?>? extra;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'model': model,
      'prompt': prompt,
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

class CompletionUsage {
  CompletionUsage({
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  });

  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  factory CompletionUsage.fromJson(Map<String, dynamic> json) {
    return CompletionUsage(
      promptTokens: _parseInt(json['prompt_tokens']),
      completionTokens: _parseInt(json['completion_tokens']),
      totalTokens: _parseInt(json['total_tokens']),
    );
  }
}

class CompletionChoice {
  CompletionChoice({
    required this.text,
    this.index,
    this.finishReason,
  });

  final String text;
  final int? index;
  final String? finishReason;

  factory CompletionChoice.fromJson(Map<String, dynamic> json) {
    return CompletionChoice(
      text: json['text'] as String? ?? '',
      index: _parseInt(json['index']),
      finishReason: json['finish_reason'] as String?,
    );
  }
}

class CompletionResponse {
  CompletionResponse({
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
  final List<CompletionChoice> choices;
  final CompletionUsage? usage;

  factory CompletionResponse.fromJson(Map<String, dynamic> json) {
    final choices = (json['choices'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CompletionChoice.fromJson)
        .toList();

    final usageJson = json['usage'];

    return CompletionResponse(
      id: json['id'] as String? ?? '',
      object: json['object'] as String?,
      created: _parseInt(json['created']),
      model: json['model'] as String?,
      choices: choices,
      usage: usageJson is Map<String, dynamic>
          ? CompletionUsage.fromJson(usageJson)
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
