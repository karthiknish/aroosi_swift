import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:aroosi_flutter/theme/theme.dart';

const String _releaseChannel = String.fromEnvironment(
  'AROOSI_RELEASE_CHANNEL',
  defaultValue: 'dev',
);
const String _runtimeVersion = String.fromEnvironment(
  'AROOSI_RUNTIME_VERSION',
  defaultValue: '-',
);
const String _updateId = String.fromEnvironment(
  'AROOSI_UPDATE_ID',
  defaultValue: '-',
);

const _AboutData _fallbackAboutData = _AboutData(
  appName: 'Aroosi',
  version: '-',
  buildNumber: '-',
  packageName: '-',
  platform: '-',
  channel: _releaseChannel,
  runtimeVersion: _runtimeVersion,
  updateId: _updateId,
);

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<_AboutData> _aboutFuture;

  @override
  void initState() {
    super.initState();
    _aboutFuture = _loadAboutData();
  }

  Future<_AboutData> _loadAboutData() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final platformLabel = _resolvePlatformLabel();

      return _AboutData(
        appName: info.appName.isNotEmpty
            ? info.appName
            : _fallbackAboutData.appName,
        version: info.version.isNotEmpty
            ? info.version
            : _fallbackAboutData.version,
        buildNumber: info.buildNumber.isNotEmpty
            ? info.buildNumber
            : _fallbackAboutData.buildNumber,
        packageName: info.packageName.isNotEmpty
            ? info.packageName
            : _fallbackAboutData.packageName,
        platform: platformLabel,
        channel: _releaseChannel,
        runtimeVersion: _runtimeVersion,
        updateId: _updateId,
      );
    } catch (_) {
      return _fallbackAboutData;
    }
  }

  String _resolvePlatformLabel() {
    if (kIsWeb) {
      return 'Web';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: FutureBuilder<_AboutData>(
        future: _aboutFuture,
        builder: (context, snapshot) {
          final about = snapshot.data ?? _fallbackAboutData;
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.lg,
            ),
            children: [
              _InfoCard(data: about, isLoading: isLoading),
              const SizedBox(height: Spacing.xl),
              Text(
                'Legal & Support',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              _LinkGroup(
                items: [
                  _LinkItem(
                    label: 'Terms of Service',
                    onTap: () => context.push('/settings/terms-of-service'),
                  ),
                  _LinkItem(
                    label: 'Privacy Policy',
                    onTap: () => context.push('/settings/privacy-policy'),
                  ),
                  _LinkItem(
                    label: 'Contact Support',
                    onTap: () => context.push('/support'),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xl),
              const _Footer(),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final _AboutData data;
  final bool isLoading;

  const _InfoCard({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(Spacing.xl),
      child: isLoading
          ? const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.appName,
                  style:
                      textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ) ??
                      AppTypography.h1.copyWith(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Version ${data.version} (${data.buildNumber})',
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  '${data.platform} • ${data.packageName}',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.lg),
                const Divider(height: 1),
                const SizedBox(height: Spacing.md),
                _MetaRow(label: 'Channel', value: data.channel),
                _MetaRow(label: 'Runtime', value: data.runtimeVersion),
                _MetaRow(label: 'Update', value: data.updateId),
              ],
            ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodySmall,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkGroup extends StatelessWidget {
  final List<_LinkItem> items;

  const _LinkGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(20);
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              CupertinoListTile(
                onTap: items[i].onTap,
                title: Text(
                  items[i].label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                trailing: Icon(
                  CupertinoIcons.chevron_right,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
              ),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinkItem {
  final String label;
  final VoidCallback onTap;

  const _LinkItem({required this.label, required this.onTap});
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final year = DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '© $year Aroosi. All rights reserved.',
          style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AboutData {
  final String appName;
  final String version;
  final String buildNumber;
  final String packageName;
  final String platform;
  final String channel;
  final String runtimeVersion;
  final String updateId;

  const _AboutData({
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.packageName,
    required this.platform,
    required this.channel,
    required this.runtimeVersion,
    required this.updateId,
  });
}
