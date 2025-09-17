import 'package:flutter/material.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Details #$id')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item ID: $id', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            const Text('Details content goes here...'),
          ],
        ),
      ),
    );
  }
}
