import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

bool isCupertinoPlatform([BuildContext? context]) {
  final platform = defaultTargetPlatform;
  return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
}
