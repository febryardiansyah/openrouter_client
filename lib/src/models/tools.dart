/// This file defines the data models related to tools that can be used in the OpenRouter API.
class ToolFunctionDefinition {
  ToolFunctionDefinition({
    required this.name,
    this.description,
    this.parameters,
  });

  /// The name of the function. This should be unique among all tools provided in the request.
  /// The name is used to identify which function to call when the model chooses to use a tool.
  final String name;

  /// An optional description of the function.
  /// This can be used to provide additional context to the model about what the function does and when it should be used.
  /// Providing a clear and concise description can help the model make better decisions about when to use the tool.
  final String? description;

  /// An optional map of parameters that the function accepts.
  /// The structure of this map can be defined based on the specific requirements of the function and the model's capabilities.
  /// Example:
  /// ```dart
  /// parameters: {
  ///   'type': 'object',
  ///   'properties': {
  ///     'query': {'type': 'string'},
  ///   },
  ///   'required': ['query'],
  /// },
  /// ```
  final Map<String, Object?>? parameters;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'name': name};

    if (description != null && description!.isNotEmpty) {
      json['description'] = description;
    }
    if (parameters != null && parameters!.isNotEmpty) {
      json['parameters'] = parameters;
    }

    return json;
  }
}

/// A class representing a tool definition that can be used in the OpenRouter API.
class ToolDefinition {
  ToolDefinition({required this.function, this.type = 'function'});

  /// The type of the tool. This can be used to categorize tools and provide additional context to the model about how the tool should be used.
  /// The default value is "function", which indicates that the tool is a function that can be called by the model. Other types can be defined based on specific use cases and requirements.
  final String type;

  /// The definition of the function that the tool represents. This includes the name, description, and parameters of the function.
  /// This information is crucial for the model to understand how to use the tool effectively and when it should be called during the conversation.
  final ToolFunctionDefinition function;

  Map<String, Object?> toJson() {
    return {'type': type, 'function': function.toJson()};
  }
}

class ToolChoice {
  ToolChoice._({required this.mode, this.functionName});

  /// The mode of tool usage. This can be "auto", "none", or "function".
  /// - "auto": The model can choose to use the tool if it determines that it would be helpful in generating a response. This allows the model to decide when to use the tool based on the context of the conversation and the information available.
  /// - "none": The model will not use the tool at all, even if it might be helpful. This can be used to disable tool usage for specific requests or conversations.
  /// - "function": The model will use the specified function from the provided tools when it determines that it would be helpful. This allows for more control over which tools the model can use and when, while still allowing the model to make decisions about when to use them.
  final String mode;

  /// The name of the function to use when the mode is set to "function". This should correspond to the name of one of the functions defined in the provided tools.
  /// This allows the model to use a specific tool when it determines that it would be helpful in generating a response, while still allowing the model to make decisions about when to use it based on the context of the conversation and the information available.
  final String? functionName;

  /// Factory constructor for creating a ToolChoice with "auto" mode.
  factory ToolChoice.auto() => ToolChoice._(mode: 'auto');

  /// Factory constructor for creating a ToolChoice with "none" mode.
  factory ToolChoice.none() => ToolChoice._(mode: 'none');

  /// Factory constructor for creating a ToolChoice with "function" mode, specifying the name of the function to use.
  factory ToolChoice.function(String name) =>
      ToolChoice._(mode: 'function', functionName: name);

  Object toJson() {
    if (mode == 'auto' || mode == 'none') {
      return mode;
    }

    return {
      'type': 'function',
      'function': {'name': functionName},
    };
  }
}

/// A class representing a tool call made by the model during a chat completion stream.
/// This includes the ID and type of the tool call, as well as the function being called and its arguments.
class ToolCallFunction {
  ToolCallFunction({this.name, this.arguments});

  /// The name of the function being called. This should correspond to the name of one of the functions defined in the provided tools.
  final String? name;

  /// The arguments being passed to the function. The structure of this can be defined based on the specific requirements of the function and the model's capabilities.
  /// This allows the model to provide specific information or parameters when calling a tool, which can help the tool perform its intended function effectively.
  final Object? arguments;

  factory ToolCallFunction.fromJson(Map<String, dynamic> json) {
    return ToolCallFunction(
      name: json['name'] as String?,
      arguments: json['arguments'],
    );
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};

    if (name != null && name!.isNotEmpty) {
      json['name'] = name;
    }
    if (arguments != null) {
      json['arguments'] = arguments;
    }

    return json;
  }
}

/// A class representing a tool call made by the model during a chat completion stream.
class ToolCall {
  ToolCall({this.id, this.type, this.function});

  /// An optional identifier for the tool call. This can be used to track specific tool calls and their associated information during the conversation.
  /// This can be helpful for understanding the context of the tool call and the actions taken by the model during the conversation, especially when multiple tool calls are made.
  final String? id;

  /// The type of the tool call. This can be used to categorize tool calls and provide additional context to the model about how the tool call should be interpreted.
  final String? type;

  /// The function being called by the model. This includes the name of the function and any arguments being passed to it.
  final ToolCallFunction? function;

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    final functionJson = json['function'];

    return ToolCall(
      id: json['id'] as String?,
      type: json['type'] as String?,
      function: functionJson is Map<String, dynamic>
          ? ToolCallFunction.fromJson(functionJson)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};

    if (id != null && id!.isNotEmpty) {
      json['id'] = id;
    }
    if (type != null && type!.isNotEmpty) {
      json['type'] = type;
    }
    if (function != null) {
      json['function'] = function!.toJson();
    }

    return json;
  }
}
