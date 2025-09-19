import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ActionsRow extends StatelessWidget {
  const ActionsRow({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    ButtonStyle style(Color color) => OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withOpacity(0.4)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: style(scheme.primary),
            onPressed: () => GoRouter.of(context).go('/search'),
            icon: const Icon(Icons.search),
            label: const Text('Search'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: style(scheme.tertiary),
            onPressed: () => GoRouter.of(context).pushNamed('mainEditProfile'),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: style(scheme.secondary),
            onPressed: () => GoRouter.of(context).pushNamed('mainSubscription'),
            icon: const Icon(Icons.workspace_premium),
            label: const Text('Upgrade'),
          ),
        ),
      ],
    );
  }
}
