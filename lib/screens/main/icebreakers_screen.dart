import 'package:flutter/material.dart';

class IcebreakersScreen extends StatelessWidget {
  const IcebreakersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prompts = [
      'What\'s your perfect weekend?',
      'Favourite local hidden gem?',
      'If you could travel anywhere tomorrow, where would you go?',
      'What\'s a hobby you\'re passionate about?'
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Icebreakers')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(prompts[index]),
          ),
        ),
      ),
    );
  }
}
