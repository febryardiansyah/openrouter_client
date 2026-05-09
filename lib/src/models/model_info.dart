class OpenRouterModel {
  OpenRouterModel({
    required this.id,
    this.name,
    this.contextLength,
    this.description,
  });

  final String id;
  final String? name;
  final int? contextLength;
  final String? description;

  factory OpenRouterModel.fromJson(Map<String, dynamic> json) {
    return OpenRouterModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      contextLength: json['context_length'] as int?,
      description: json['description'] as String?,
    );
  }
}

class ModelsResponse {
  ModelsResponse({required this.data});

  final List<OpenRouterModel> data;

  factory ModelsResponse.fromJson(Map<String, dynamic> json) {
    final models = (json['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OpenRouterModel.fromJson)
        .toList();

    return ModelsResponse(data: models);
  }
}
