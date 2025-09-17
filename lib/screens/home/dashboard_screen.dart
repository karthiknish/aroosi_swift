import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), actions: [
        IconButton(
          onPressed: () => context.go('/settings'),
          icon: const Icon(Icons.settings),
        )
      ]),
      body: ListView.builder(
        itemCount: 20,
        itemBuilder: (context, index) => ListTile(
          title: Text('Item #$index'),
          subtitle: const Text('Tap to view details'),
          onTap: () => context.go('/details/$index'),
        ),
      ),
    );
  }
}
