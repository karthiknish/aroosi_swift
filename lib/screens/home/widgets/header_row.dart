import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HeaderRow extends StatelessWidget {
  const HeaderRow({super.key, required this.unreadCount});
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.favorite,
            label: 'Matches',
            onTap: () => GoRouter.of(context).pushNamed('mainMatches'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.bookmark,
            label: 'Shortlists',
            onTap: () => GoRouter.of(context).pushNamed('mainShortlists'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.mark_chat_unread_outlined,
            label: unreadCount > 0 ? '$unreadCount Unread' : 'Messages',
            color: unreadCount > 0 ? scheme.primary : null,
            onTap: () => GoRouter.of(context).pushNamed('mainConversations'),
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color?.withOpacity(0.12) ?? scheme.surfaceContainerHighest;
    final fg = color ?? scheme.onSurfaceVariant;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: fg),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
