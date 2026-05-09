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
