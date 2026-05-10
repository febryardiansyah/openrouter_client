import 'package:flutter/material.dart';
import 'package:openrouter_client/openrouter_client.dart';

import '../widgets/example_scaffold.dart';
import '../widgets/section_card.dart';
import '../widgets/status_banner.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key, required this.apiKey});

  final String apiKey;

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  List<OpenRouterModel> _models = const [];
  String? _errorText;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });

    final client = OpenRouterClient(apiKey: widget.apiKey);
    try {
      final response = await client.listModels();
      setState(() {
        _models = response.data;
      });
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
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExampleScaffold(
      title: 'List models',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _loadModels,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_loading ? 'Loading...' : 'Refresh models'),
                ),
              ),
            ],
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 16),
            StatusBanner(
              text: _errorText!,
              backgroundColor: const Color(0xFFFFE2E2),
              textColor: const Color(0xFF7A1C1C),
            ),
          ],
          const SizedBox(height: 16),
          SectionCard(
            title: 'Available models',
            child: _models.isEmpty
                ? const Text('No models loaded yet.')
                : Column(
                    children: _models
                        .map(
                          (model) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  model.id,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                if (model.name != null && model.name!.isNotEmpty)
                                  Text(model.name!),
                                if (model.description != null &&
                                    model.description!.isNotEmpty)
                                  Text(
                                    model.description!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(height: 1.4),
                                  ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
