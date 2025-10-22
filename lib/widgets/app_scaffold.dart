import 'package:flutter/cupertino.dart';

import 'package:aroosi_flutter/theme/theme.dart';
import 'package:aroosi_flutter/theme/typography.dart';
import 'package:aroosi_flutter/widgets/email_verification_banner.dart';
import 'package:aroosi_flutter/widgets/brand/aurora_background.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: child,
      ),
    );
    
    return AuroraBackground(
      enableTexture: true,
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: AppColors.background.withValues(alpha: 0.9),
          border: null,
          middle: _CupertinoAppBarTitle(title: title),
          leading: leading,
          trailing: actions != null && actions!.isNotEmpty
              ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
              : null,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.lg,
              Spacing.lg + 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EmailVerificationBanner(),
                const SizedBox(height: Spacing.lg),
                child,
                if (floatingActionButton != null) ...[
                  const SizedBox(height: 80),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CupertinoAppBarTitle extends StatelessWidget {
  const _CupertinoAppBarTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Curated by Aroosi',
          style: AppTypography.caption.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
