import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:aroosi_flutter/platform/platform_utils.dart';
import 'package:aroosi_flutter/theme/theme.dart';
import 'package:aroosi_flutter/widgets/email_verification_banner.dart';

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
    if (isCupertinoPlatform(context)) {
      final content = SafeArea(
        bottom: false,
        child: Padding(padding: const EdgeInsets.all(Spacing.md), child: child),
      );
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
          leading: leading,
          trailing: actions != null && actions!.isNotEmpty
              ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
              : null,
        ),
        child: floatingActionButton == null
            ? content
            : Stack(
                children: [
                  content,
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: floatingActionButton!,
                  ),
                ],
              ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(title), leading: leading, actions: actions),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EmailVerificationBanner(),
            Expanded(child: child),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
