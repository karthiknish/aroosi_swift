import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'base_step.dart';
import 'step_constants.dart';

/// Professional step widget
class StepProfessional extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final OnDataUpdate? onDataUpdate;
  final GlobalKey<FormState>? formKey;

  const StepProfessional({
    super.key,
    this.initialData = const {},
    this.onDataUpdate,
    this.formKey,
  });

  @override
  State<StepProfessional> createState() => _StepProfessionalState();
}

class _StepProfessionalState extends State<StepProfessional> {
  late final TextEditingController _educationCtrl;
  late final TextEditingController _occupationCtrl;
  late final TextEditingController _annualIncomeCtrl;

  @override
  void initState() {
    super.initState();
    _educationCtrl = TextEditingController(
      text: widget.initialData[StepConstants.education] as String? ?? '',
    );
    _occupationCtrl = TextEditingController(
      text: widget.initialData[StepConstants.occupation] as String? ?? '',
    );

    // Initialize annual income from data if it's a number
    final income = widget.initialData[StepConstants.annualIncome];
    if (income != null) {
      if (income is num) {
        _annualIncomeCtrl = TextEditingController(
          text: income.toInt().toString(),
        );
      } else if (income is String) {
        _annualIncomeCtrl = TextEditingController(text: income);
      }
    } else {
      _annualIncomeCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _educationCtrl.dispose();
    _occupationCtrl.dispose();
    _annualIncomeCtrl.dispose();
    super.dispose();
  }

  void _updateField(String key, dynamic value) {
    widget.onDataUpdate?.call(key, value);
  }

  String? _validateEducation(String? value) {
    return validateMinLength(value, 2, 'education level');
  }

  String? _validateOccupation(String? value) {
    return validateMinLength(value, 2, 'occupation');
  }

  String? _validateAnnualIncome(String? value) {
    return validateNumber(
      value,
      min: StepConstants.minimumIncome,
      max: StepConstants.maximumIncome,
      fieldName: 'annual income',
      required: true,
    );
  }

  // Common utility methods
  String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  String? validateNumber(
    String? value, {
    required num min,
    required num max,
    required String fieldName,
    bool required = true,
  }) {
    if (required && (value == null || value.trim().isEmpty)) {
      return '$fieldName is required';
    }
    if (value != null && value.trim().isNotEmpty) {
      final num? parsed = num.tryParse(value.trim());
      if (parsed == null) {
        return '$fieldName must be a valid number';
      }
      if (parsed < min || parsed > max) {
        return '$fieldName must be between $min and $max';
      }
    }
    return null;
  }

  BoxDecoration cupertinoDecoration(
    BuildContext context, {
    bool hasError = false,
  }) {
    return BoxDecoration(
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      border: Border.all(
        color: hasError ? CupertinoColors.systemRed : AppColors.primary,
        width: hasError ? 2.0 : 1.0,
      ),
      borderRadius: BorderRadius.circular(10.0),
    );
  }

  Padding cupertinoFieldPadding(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }

  List<TextInputFormatter> get currencyFormatter => [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
  ];

  void _onIncomeChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      final num? parsed = num.tryParse(trimmed);
      if (parsed != null) {
        _updateField(StepConstants.annualIncome, parsed.toDouble());
      }
    } else {
      _updateField(StepConstants.annualIncome, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final textStyle = cupertinoTheme.textTheme.textStyle;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Education
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Education',
                style: textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: cupertinoDecoration(
                  context,
                  hasError: _validateEducation(_educationCtrl.text) != null,
                ),
                child: cupertinoFieldPadding(
                  CupertinoTextField(
                    controller: _educationCtrl,
                    placeholder: 'Enter your education',
                    placeholderStyle: textStyle.copyWith(
                      color: CupertinoColors.placeholderText,
                    ),
                    style: textStyle,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                    ),
                    onChanged: (value) =>
                        _updateField(StepConstants.education, value.trim()),
                  ),
                ),
              ),
              if (_validateEducation(_educationCtrl.text) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _validateEducation(_educationCtrl.text)!,
                    style: textStyle.copyWith(
                      color: CupertinoColors.systemRed,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Occupation
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Occupation',
                style: textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: cupertinoDecoration(
                  context,
                  hasError: _validateOccupation(_occupationCtrl.text) != null,
                ),
                child: cupertinoFieldPadding(
                  CupertinoTextField(
                    controller: _occupationCtrl,
                    placeholder: 'Enter your occupation',
                    placeholderStyle: textStyle.copyWith(
                      color: CupertinoColors.placeholderText,
                    ),
                    style: textStyle,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                    ),
                    onChanged: (value) =>
                        _updateField(StepConstants.occupation, value.trim()),
                  ),
                ),
              ),
              if (_validateOccupation(_occupationCtrl.text) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _validateOccupation(_occupationCtrl.text)!,
                    style: textStyle.copyWith(
                      color: CupertinoColors.systemRed,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Annual Income
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Annual income (£)',
                style: textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: cupertinoDecoration(
                  context,
                  hasError:
                      _validateAnnualIncome(_annualIncomeCtrl.text) != null,
                ),
                child: cupertinoFieldPadding(
                  CupertinoTextField(
                    controller: _annualIncomeCtrl,
                    placeholder: 'e.g., 50000',
                    placeholderStyle: textStyle.copyWith(
                      color: CupertinoColors.placeholderText,
                    ),
                    style: textStyle,
                    keyboardType: TextInputType.number,
                    inputFormatters: currencyFormatter,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                    ),
                    onChanged: _onIncomeChanged,
                  ),
                ),
              ),
              if (_validateAnnualIncome(_annualIncomeCtrl.text) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _validateAnnualIncome(_annualIncomeCtrl.text)!,
                    style: textStyle.copyWith(
                      color: CupertinoColors.systemRed,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Professional information card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.systemBlue.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.briefcase,
                      size: 20,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'About your professional information',
                      style: textStyle.copyWith(
                        color: CupertinoColors.secondaryLabel,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your education and occupation help others understand your background. Income is kept private and only used for compatibility matching.',
                  style: textStyle.copyWith(
                    color: CupertinoColors.secondaryLabel,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
