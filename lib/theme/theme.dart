import 'package:flutter/cupertino.dart';
import 'colors.dart';
import 'typography.dart';

export 'colors.dart';
export 'spacing.dart';
export 'typography.dart';
export 'motion.dart';

CupertinoThemeData buildCupertinoTheme() {
  return CupertinoThemeData(
    primaryColor: AppColors.primary,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    barBackgroundColor: AppColors.surface,
    primaryContrastingColor: AppColors.onPrimary,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.primary,
      textStyle: TextStyle(
        color: AppColors.text,
        fontFamily: 'SF Pro Text',
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
      navTitleTextStyle: TextStyle(
        color: AppColors.text,
        fontFamily: 'SF Pro Display',
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      navLargeTitleTextStyle: TextStyle(
        color: AppColors.text,
        fontFamily: 'SF Pro Display',
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
      pickerTextStyle: TextStyle(
        color: AppColors.text,
        fontFamily: 'SF Pro Text',
        fontSize: 21,
        fontWeight: FontWeight.w400,
      ),
      dateTimePickerTextStyle: TextStyle(
        color: AppColors.text,
        fontFamily: 'SF Pro Text',
        fontSize: 21,
        fontWeight: FontWeight.w400,
      ),
      tabLabelTextStyle: TextStyle(
        color: AppColors.text,
        fontFamily: 'SF Pro Text',
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
      actionTextStyle: TextStyle(
        color: AppColors.primary,
        fontFamily: 'SF Pro Text',
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
    ),
    applyThemeToAll: true,
  );
}
