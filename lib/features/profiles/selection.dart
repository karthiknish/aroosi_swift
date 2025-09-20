import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the most recently selected profile ID to support context-aware navigation.
final lastSelectedProfileIdProvider =
    NotifierProvider<LastSelectedProfileId, String?>(LastSelectedProfileId.new);

class LastSelectedProfileId extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}
