import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl {
    try {
      return dotenv.env['API_BASE_URL']?.trim() ?? '';
    } catch (_) {
      // When dotenv isn't initialized (e.g., tests), return empty string
      return '';
    }
  }
}
