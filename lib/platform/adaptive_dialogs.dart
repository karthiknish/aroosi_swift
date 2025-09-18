import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:aroosi_flutter/platform/platform_utils.dart';

Future<bool> showAdaptiveConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'OK',
  String cancelText = 'Cancel',
}) async {
  if (isCupertinoPlatform(context)) {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(cancelText),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(cancelText)),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(confirmText)),
          ],
        ),
      ) ??
      false;
}
