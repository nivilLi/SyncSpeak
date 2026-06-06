import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/interpreter_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SimultaneousInterpretationApp(),
    ),
  );
}

class SimultaneousInterpretationApp extends StatelessWidget {
  const SimultaneousInterpretationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '同声传译',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B2FBE),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1a1a2e),
      ),
      home: const InterpreterScreen(),
    );
  }
}
