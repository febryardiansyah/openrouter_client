class ToolFunctionDefinition {
  ToolFunctionDefinition({
    required this.name,
    this.description,
    this.parameters,
  });

  final String name;
  final String? description;
  final Map<String, Object?>? parameters;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'name': name,
    };

    if (description != null && description!.isNotEmpty) {
      json['description'] = description;
    }
    if (parameters != null && parameters!.isNotEmpty) {
      json['parameters'] = parameters;
    }

    return json;
  }
}

class ToolDefinition {
  ToolDefinition({
    required this.function,
    this.type = 'function',
  });

  final String type;
  final ToolFunctionDefinition function;

  Map<String, Object?> toJson() {
    return {
      'type': type,
      'function': function.toJson(),
    };
  }
}

class ToolChoice {
  ToolChoice._({
    required this.mode,
    this.functionName,
  });

  final String mode;
  final String? functionName;

  factory ToolChoice.auto() => ToolChoice._(mode: 'auto');

  factory ToolChoice.none() => ToolChoice._(mode: 'none');

  factory ToolChoice.function(String name) =>
      ToolChoice._(mode: 'function', functionName: name);

  Object toJson() {
    if (mode == 'auto' || mode == 'none') {
      return mode;
    }

    return {
      'type': 'function',
      'function': {
        'name': functionName,
      },
    };
  }
}


class ToolCallFunction {
  ToolCallFunction({
    this.name,
    this.arguments,
  });

  final String? name;
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

class ToolCall {
  ToolCall({
    this.id,
    this.type,
    this.function,
  });

  final String? id;
  final String? type;
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

