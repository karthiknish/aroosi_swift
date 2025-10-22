import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/features/safety/safety_controller.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    // Load blocked users on first open
    Future.microtask(
      () => ref.read(safetyControllerProvider.notifier).refreshBlocked(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(safetyControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(safetyControllerProvider.notifier).refreshBlocked(),
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(state.error!)),
                          TextButton(
                            onPressed: () => ref
                                .read(safetyControllerProvider.notifier)
                                .refreshBlocked(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: state.blockedUsers.isEmpty
                        ? const Center(child: Text('No blocked users'))
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: state.blockedUsers.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final u = state.blockedUsers[index];
                              final name =
                                  u['fullName']?.toString() ??
                                  u['name']?.toString() ??
                                  'User';
                              final id =
                                  u['id']?.toString() ??
                                  u['_id']?.toString() ??
                                  '';
                              return ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person_outline),
                                ),
                                title: Text(name),
                                trailing: TextButton(
                                  onPressed: id.isEmpty
                                      ? null
                                      : () async {
                                          final ok = await ref
                                              .read(
                                                safetyControllerProvider
                                                    .notifier,
                                              )
                                              .unblock(id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                ok
                                                    ? 'Unblocked $name'
                                                    : 'Failed to unblock',
                                              ),
                                            ),
                                          );
                                          }
                                        },
                                  child: const Text('Unblock'),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            ref.read(safetyControllerProvider.notifier).refreshBlocked(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
