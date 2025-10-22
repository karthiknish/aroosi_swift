import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aroosi_flutter/theme/colors.dart';

/// Base widget for onboarding steps with common functionality
abstract class BaseStepWidget extends StatelessWidget {
  const BaseStepWidget({super.key});

  /// Step data that can be updated by child widgets
  final Map<String, dynamic> data = const {};

  /// Method to validate the current step
  Future<bool> validateStep() async => true;

  /// Method to get step-specific data
  Map<String, dynamic> getStepData() => {};

  /// Method to update step data
  void updateData(String key, dynamic value) {}

  /// Common decoration for form fields
  InputDecoration decoration(
    BuildContext context,
    String label, {
    String? hint,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  /// Common phone number formatting
  String? normalizePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final digits = cleaned.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 10 && digits.length <= 15) {
      return '+$digits';
    }
    return phone.trim();
  }

  /// Common phone validation
  bool isValidPhone(String value) {
    final normalized = normalizePhoneNumber(value);
    if (normalized == null) return false;
    return RegExp(r'^\+[1-9][\d]{9,14}$').hasMatch(normalized);
  }

  /// Common age calculation
  int? ageFromDob(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    final hadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) age -= 1;
    return age;
  }

  /// Common text capitalization
  String capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  /// Common date formatting
  String formatDob(DateTime? dob) {
    if (dob == null) return '';
    return '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
  }

  /// Common validation for minimum words
  bool hasAtLeastWords(String text, int words) {
    final tokens = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return tokens.length >= words;
  }

  /// Common height validation
  String? validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your height';
    }
    final num? parsed = num.tryParse(value.trim());
    if (parsed == null || parsed < 100 || parsed > 250) {
      return 'Height must be between 100-250 cm';
    }
    return null;
  }

  /// Common name validation
  String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return '$fieldName must be less than 50 characters';
    }
    return null;
  }

  /// Common text validation with minimum length
  String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Common dropdown validation
  String? validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Common numeric validation
  String? validateNumber(
    String? value, {
    int? min,
    int? max,
    String fieldName = 'Value',
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Please enter $fieldName' : null;
    }
    final num? parsed = num.tryParse(value.trim());
    if (parsed == null) {
      return 'Please enter a valid number';
    }
    if (min != null && parsed < min) {
      return '$fieldName must be at least $min';
    }
    if (max != null && parsed > max) {
      return '$fieldName must be no more than $max';
    }
    return null;
  }

  /// Common currency input formatter
  List<TextInputFormatter> get currencyFormatter => [
    FilteringTextInputFormatter.digitsOnly,
  ];

  /// Common numeric input formatter
  List<TextInputFormatter> get numericFormatter => [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  ];

  /// Common phone input formatter
  List<TextInputFormatter> get phoneFormatter => [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
  ];
}

/// Callback type for step data updates
typedef OnDataUpdate = void Function(String key, dynamic value);
