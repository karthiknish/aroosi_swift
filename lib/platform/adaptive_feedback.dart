import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/platform/platform_utils.dart';

@Deprecated('Use ToastService.instance.{info,success,warning,error,show} instead for centralized toasts')
void showAdaptiveToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
}) {
  ToastService.instance.show(message, type: type);
}

Future<int?> showAdaptiveActionSheet(BuildContext context, {required String title, required List<String> actions, String cancelText = 'Cancel'}) async {
  if (isCupertinoPlatform(context)) {
    return await showCupertinoModalPopup<int>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(title),
        actions: [
          for (var i = 0; i < actions.length; i++)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(i),
              isDestructiveAction: true,
              child: Text(actions[i]),
            )
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(cancelText),
        ),
      ),
    );
  }
  // Material: bottom sheet list of destructive actions
  return await showModalBottomSheet<int>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          ListTile(title: Text(title, style: Theme.of(ctx).textTheme.titleMedium)),
          for (var i = 0; i < actions.length; i++)
            ListTile(
              title: Text(
                actions[i],
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () => Navigator.of(ctx).pop(i),
            ),
          ListTile(title: Text(cancelText), onTap: () => Navigator.of(ctx).pop())
        ],
      ),
    ),
  );
}
