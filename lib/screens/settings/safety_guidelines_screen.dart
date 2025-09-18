import 'package:flutter/material.dart';

class SafetyGuidelinesScreen extends StatelessWidget {
  const SafetyGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guidelines = [
      'Keep conversations on the platform until you feel comfortable.',
      'Be mindful when sharing personal information.',
      'Report any suspicious behaviour to the Aroosi team.',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Safety Guidelines')),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: guidelines.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(guidelines[index]),
          ),
        ),
      ),
    );
  }
}
