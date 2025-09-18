import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/features/profiles/selection.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastId = ref.watch(lastSelectedProfileIdProvider);
    final demoDetailsRoute = '/details/${lastId ?? '123'}';
    final destinations = <_Destination>[
      _Destination('Conversations', Icons.chat_bubble_outline, '/main'),
      _Destination('Chat', Icons.message_outlined, '/main/chat'),
      _Destination('Matches', Icons.favorite_border, '/main/matches'),
      _Destination('Quick Picks', Icons.flash_on_outlined, '/main/quick-picks'),
      _Destination(
        'Shortlists',
        Icons.bookmark_add_outlined,
        '/main/shortlists',
      ),
      _Destination('Icebreakers', Icons.lightbulb_outline, '/main/icebreakers'),
      _Destination(
        'Interests',
        Icons.local_activity_outlined,
        '/main/interests',
      ),
      _Destination('Edit Profile', Icons.person_outline, '/main/edit-profile'),
      _Destination(
        'Profile Detail (demo)',
        Icons.badge_outlined,
        demoDetailsRoute,
      ),
      _Destination(
        'Subscription',
        Icons.workspace_premium_outlined,
        '/main/subscription',
      ),
      _Destination(
        'AI Chatbot',
        Icons.smart_toy_outlined,
        '/support/ai-chatbot',
      ),
      _Destination('Support Contact', Icons.support_agent, '/support'),
    ];

    int tileIndex = 0;
    Widget animatedTile(Widget child) => FadeSlideIn(
      delay: Duration(milliseconds: 60 * tileIndex++),
      beginOffset: const Offset(0, 0.05),
      child: child,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: FadeThrough(
        delay: AppMotionDurations.fast,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: destinations.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, index) {
            final destination = destinations[index];
            return animatedTile(
              ListTile(
                leading: Icon(destination.icon),
                title: Text(destination.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(destination.route),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}
