import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const OpenRouterExampleApp());
}

class OpenRouterExampleApp extends StatelessWidget {
  const OpenRouterExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1F6FEB);
    return MaterialApp(
      title: 'OpenRouter Client Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        fontFamily: 'Avenir',
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF3F6FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      home: const OpenRouterHomePage(),
    );
  }
}
