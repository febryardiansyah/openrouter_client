import 'tools.dart';

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    this.toolCalls,
    this.toolCallId,
  });

  /// The role of the message sender. This can be "user", "assistant", or "system".
  final String role;

  /// The content of the message.
  /// This can be a string, a list of strings, or a more complex structure depending on the model and tools being used.
  final Object content;

  /// Optional list of tool calls associated with this message.
  /// This allows the message to include information about any tools that were called as part of the conversation, which can be useful for tracking the flow of the conversation and the actions taken by the model
  final List<ToolCall>? toolCalls;

  /// Optional identifier for a specific tool call.
  /// This can be used to link the message to a particular tool call, which can be helpful for understanding the context of the message and the actions taken by the model during the conversation.
  final String? toolCallId;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final toolCallsJson = json['tool_calls'];

    return ChatMessage(
      role: json['role'] as String? ?? '',
      content: json['content'] ?? '',
      toolCalls: toolCallsJson is List
          ? toolCallsJson
                .whereType<Map<String, dynamic>>()
                .map(ToolCall.fromJson)
                .toList()
          : null,
      toolCallId: json['tool_call_id'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'role': role, 'content': content};

    if (toolCalls != null && toolCalls!.isNotEmpty) {
      json['tool_calls'] = toolCalls!.map((call) => call.toJson()).toList();
    }
    if (toolCallId != null && toolCallId!.isNotEmpty) {
      json['tool_call_id'] = toolCallId;
    }

    return json;
  }
}

class ChatCompletionRequest {
  ChatCompletionRequest({
    required this.model,
    this.models,
    required this.messages,
    this.temperature,
    this.maxCompletionTokens,
    this.maxTokens,
    this.topP,
    this.tools,
    this.toolChoice,
    this.extra,
  });

  /// The model to use for generating the chat completion.
  /// Go to the OpenRouter dashboard to see a list of available models and their capabilities.
  final String model;

  /// Optional list of models to use for the completion.
  /// Use this when routing across multiple models.
  final List<String>? models;

  /// The list of messages to generate a completion for.
  /// The messages should be in the format of a conversation, with each message having a role (e.g., "user", "assistant") and content.
  final List<ChatMessage> messages;

  /// Optional parameter to control the behavior of the chat completion.
  final double? temperature;

  /// Optional parameter to specify the maximum number of tokens to generate in the completion.
  final int? maxCompletionTokens;

  /// Optional parameter to specify the maximum number of tokens to generate in the completion.
  /// Deprecated by the API in favor of `maxCompletionTokens`.
  final int? maxTokens;

  /// Optional parameter to control the diversity of the generated completion.
  /// Higher values (e.g., 0.8) will result in more diverse completions, while lower values (e.g., 0.2) will make the output more focused and deterministic.
  final double? topP;

  /// Optional list of tools that the model can use during the completion.
  /// This allows the model to perform specific actions or access external information as part of generating the response.
  final List<ToolDefinition>? tools;

  /// Optional parameter to specify how the model should choose which tools to use during the completion.
  /// This can be used to guide the model's behavior when multiple tools are available.
  final ToolChoice? toolChoice;

  /// Optional map of additional parameters that may be required by specific models or tools.
  final Map<String, Object?>? extra;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'model': model,
      'messages': messages.map((message) => message.toJson()).toList(),
    };

    if (temperature != null) {
      json['temperature'] = temperature;
    }
    if (maxCompletionTokens != null) {
      json['max_completion_tokens'] = maxCompletionTokens;
    }
    if (maxTokens != null) {
      json['max_tokens'] = maxTokens;
    }
    if (topP != null) {
      json['top_p'] = topP;
    }
    if (models != null && models!.isNotEmpty) {
      json['models'] = models;
    }
    if (tools != null && tools!.isNotEmpty) {
      json['tools'] = tools!.map((tool) => tool.toJson()).toList();
    }
    if (toolChoice != null) {
      json['tool_choice'] = toolChoice!.toJson();
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
  ChatCompletionChoice({required this.message, this.index, this.finishReason});

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
    this.systemFingerprint,
    this.serviceTier,
    this.openrouterMetadata,
    this.usage,
  });

  /// A unique identifier for the chat completion response.
  final String id;

  /// The type of object returned in the response. This is typically "chat.completion" for chat completion responses.
  final String? object;

  /// The timestamp (in seconds since the Unix epoch) when the chat completion was created.
  final int? created;

  /// The model that was used to generate the chat completion.
  final String? model;

  /// System fingerprint of the model used by the provider.
  final String? systemFingerprint;

  /// The service tier used by the upstream provider for this request.
  final String? serviceTier;

  /// A list of choices generated by the model in response to the chat completion request.
  /// Each choice represents a possible completion generated by the model, and may include information about the
  final List<ChatCompletionChoice> choices;

  /// Optional OpenRouter metadata included when enabled via headers.
  final Map<String, dynamic>? openrouterMetadata;

  /// An object containing information about the token usage for the chat completion.
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
        systemFingerprint: json['system_fingerprint'] as String?,
        serviceTier: json['service_tier'] as String?,
      choices: choices,
        openrouterMetadata: json['openrouter_metadata'] is Map<String, dynamic>
          ? json['openrouter_metadata'] as Map<String, dynamic>
          : null,
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
