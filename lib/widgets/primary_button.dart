import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:aroosi_flutter/platform/platform_utils.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCupertinoPlatform(context)) {
      return CupertinoButton.filled(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CupertinoActivityIndicator(),
              )
            : Text(label),
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : Text(label),
    );
  }
}
