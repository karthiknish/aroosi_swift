import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/platform/adaptive_dialogs.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/primary_button.dart';
import 'package:aroosi_flutter/widgets/retryable_network_image.dart';

// Simplified feature access - all features are free
class FeatureAccess {
  const FeatureAccess();

  bool can(String feature) => true;
  int usageLimit(String metric) => -1;
  bool hasUnlimited(String metric) => true;
}

class FeatureAccessController extends Notifier<FeatureAccess> {
  @override
  FeatureAccess build() => const FeatureAccess();
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Always fetch latest profile on mount
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authControllerProvider.notifier).refreshProfileOnly();
    });
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh profile when widget is updated (e.g., after returning from edit profile)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authControllerProvider.notifier).refreshProfileOnly();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch latest profile when screen regains focus (like RN useFocusEffect)
    // Note: addScopedWillPopCallback is deprecated, but keeping functionality for now
    final route = ModalRoute.of(context);
    if (route != null) {
      // Using addScopedWillPopCallback for backward compatibility
      // ignore: deprecated_member_use
      route.addScopedWillPopCallback(_onFocus);
    }
  }

  Future<bool> _onFocus() async {
    await ref.read(authControllerProvider.notifier).refreshProfileOnly();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final authCtrl = ref.read(authControllerProvider.notifier);

    if (auth.loading || auth.profile == null) {
      return const AppScaffold(
        title: 'Profile',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final name = (auth.profile?.fullName?.trim().isNotEmpty ?? false)
        ? auth.profile!.fullName!.trim()
        : 'Your Name';
    final email = auth.profile?.email ?? '';
    final avatar = auth.profile?.profileImageUrls?.isNotEmpty ?? false
        ? auth.profile!.profileImageUrls!.first
        : null;

    return AppScaffold(
      title: 'Profile',
      child: RefreshIndicator(
        key: UniqueKey(),
        onRefresh: () async {
          await authCtrl.refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            MediaQuery.of(context).padding.bottom + 80,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(name: name, email: email, avatarUrl: avatar),
              const SizedBox(height: 24),
              _ProfileQuickActions(
                onEditProfile: () => context.push('/main/edit-profile'),
                onPrivacySettings: () => context.push('/settings/privacy'),
                onSupport: () => context.push('/support'),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(email),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Log out',
                onPressed: auth.isAuthenticated
                    ? () async {
                        final confirm = await showAdaptiveConfirm(
                          context,
                          title: 'Log out',
                          message: 'Are you sure you want to log out?',
                          confirmText: 'Log out',
                          cancelText: 'Cancel',
                        );
                        if (!context.mounted) return;
                        if (confirm) {
                          await authCtrl.logout();
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  final String name;
  final String email;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (avatarUrl != null && avatarUrl!.isNotEmpty)
            CircleAvatar(
              radius: 42,
              child: ClipOval(
                child: RetryableNetworkImage(
                  url: avatarUrl!,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ),
              ),
            )
          else
            CircleAvatar(
              radius: 42,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                name.trim().isNotEmpty
                    ? name.trim().substring(0, 1).toUpperCase()
                    : 'A',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileQuickActions extends StatelessWidget {
  const _ProfileQuickActions({
    required this.onEditProfile,
    required this.onPrivacySettings,
    required this.onSupport,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onPrivacySettings;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ActionButton(
          icon: Icons.edit,
          label: 'Edit profile',
          onTap: onEditProfile,
        ),
        _ActionButton(
          icon: Icons.privacy_tip,
          label: 'Privacy settings',
          onTap: onPrivacySettings,
        ),
        _ActionButton(
          icon: Icons.support_agent,
          label: 'Support',
          onTap: onSupport,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
