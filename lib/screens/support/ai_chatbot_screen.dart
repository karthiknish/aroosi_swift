import 'package:flutter/material.dart';

class AIChatbotScreen extends StatelessWidget {
  const AIChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Chatbot')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) => Align(
          alignment: index.isEven ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(index.isEven
                ? 'How can the Aroosi assistant help you today?'
                : 'I have a question about managing my matches.'),
          ),
        ),
      ),
    );
  }
}
