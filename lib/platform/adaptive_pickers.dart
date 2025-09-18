import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:aroosi_flutter/platform/platform_utils.dart';
import 'package:aroosi_flutter/theme/theme.dart';

Future<DateTime?> showAdaptiveDatePicker(BuildContext context, {DateTime? initialDate, DateTime? firstDate, DateTime? lastDate}) async {
  initialDate ??= DateTime.now();
  firstDate ??= DateTime(1900);
  lastDate ??= DateTime(2100);
  if (isCupertinoPlatform(context)) {
    DateTime temp = initialDate;
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: AppColors.surface,
        child: Column(
          children: [
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: firstDate,
                maximumDate: lastDate,
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
            CupertinoButton(
              child: const Text('Done'),
              onPressed: () => Navigator.of(ctx).pop(),
            )
          ],
        ),
      ),
    );
    return temp;
  }
  return showDatePicker(context: context, initialDate: initialDate, firstDate: firstDate, lastDate: lastDate);
}

Future<TimeOfDay?> showAdaptiveTimePicker(BuildContext context, {TimeOfDay? initialTime}) async {
  initialTime ??= TimeOfDay.now();
  if (isCupertinoPlatform(context)) {
    TimeOfDay temp = initialTime;
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: AppColors.surface,
        child: Column(
          children: [
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                onDateTimeChanged: (d) => temp = TimeOfDay.fromDateTime(d),
              ),
            ),
            CupertinoButton(child: const Text('Done'), onPressed: () => Navigator.of(ctx).pop())
          ],
        ),
      ),
    );
    return temp;
  }
  return showTimePicker(context: context, initialTime: initialTime);
}
