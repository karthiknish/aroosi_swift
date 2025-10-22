import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'base_step.dart';
import 'step_constants.dart';

/// Cultural step widget
class StepCultural extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final OnDataUpdate? onDataUpdate;
  final GlobalKey<FormState>? formKey;

  const StepCultural({
    super.key,
    this.initialData = const {},
    this.onDataUpdate,
    this.formKey,
  });

  @override
  State<StepCultural> createState() => _StepCulturalState();
}

class _StepCulturalState extends State<StepCultural> {
  late final TextEditingController _ethnicityCtrl;

  @override
  void initState() {
    super.initState();
    _ethnicityCtrl = TextEditingController(
      text: widget.initialData[StepConstants.ethnicity] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _ethnicityCtrl.dispose();
    super.dispose();
  }

  void _updateField(String key, dynamic value) {
    widget.onDataUpdate?.call(key, value);
  }

  String? _validateEthnicity(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional field
    if (value.trim().length < 2) {
      return 'Ethnicity must be at least 2 characters';
    }
    return null;
  }

  // Common utility methods
  String capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
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

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final textStyle = cupertinoTheme.textTheme.textStyle;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mother Tongue and Religion
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mother tongue (optional)',
                      style: textStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: cupertinoDecoration(context),
                      child: cupertinoFieldPadding(
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _showMotherTonguePicker(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                (widget.initialData[StepConstants.motherTongue]
                                                as String? ??
                                            '')
                                        .isEmpty
                                    ? 'Prefer not to say'
                                    : capitalize(
                                        widget.initialData[StepConstants
                                                    .motherTongue]
                                                as String? ??
                                            '',
                                      ),
                                style: textStyle.copyWith(
                                  color: CupertinoColors.label,
                                ),
                              ),
                              const Icon(CupertinoIcons.chevron_down, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Religion (optional)',
                      style: textStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: cupertinoDecoration(context),
                      child: cupertinoFieldPadding(
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _showReligionPicker(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                (widget.initialData[StepConstants.religion]
                                                as String? ??
                                            '')
                                        .isEmpty
                                    ? 'Prefer not to say'
                                    : capitalize(
                                        widget.initialData[StepConstants
                                                    .religion]
                                                as String? ??
                                            '',
                                      ),
                                style: textStyle.copyWith(
                                  color: CupertinoColors.label,
                                ),
                              ),
                              const Icon(CupertinoIcons.chevron_down, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ethnicity
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ethnicity (optional)',
                style: textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: cupertinoDecoration(
                  context,
                  hasError: _validateEthnicity(_ethnicityCtrl.text) != null,
                ),
                child: cupertinoFieldPadding(
                  CupertinoTextField(
                    controller: _ethnicityCtrl,
                    placeholder: 'e.g., British Afghan',
                    placeholderStyle: textStyle.copyWith(
                      color: CupertinoColors.placeholderText,
                    ),
                    style: textStyle,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                    ),
                    onChanged: (value) {
                      final trimmed = value.trim();
                      if (trimmed.isEmpty) {
                        _updateField(StepConstants.ethnicity, null);
                      } else {
                        _updateField(StepConstants.ethnicity, trimmed);
                      }
                    },
                  ),
                ),
              ),
              if (_validateEthnicity(_ethnicityCtrl.text) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _validateEthnicity(_ethnicityCtrl.text)!,
                    style: textStyle.copyWith(
                      color: CupertinoColors.systemRed,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Cultural information card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CupertinoColors.systemBlue.withValues(alpha: 0.05),
                  CupertinoColors.systemPurple.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.person_3,
                      size: 20,
                      color: CupertinoColors.systemBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'About your cultural background',
                      style: textStyle.copyWith(
                        color: CupertinoColors.systemBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your cultural background helps us find matches who share similar values and traditions. All fields in this section are optional.',
                  style: textStyle.copyWith(
                    color: CupertinoColors.secondaryLabel,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Skip option
          Center(
            child: CupertinoButton(
              onPressed: () {
                // Clear all cultural fields
                _updateField(StepConstants.motherTongue, null);
                _updateField(StepConstants.religion, null);
                _updateField(StepConstants.ethnicity, null);
                _ethnicityCtrl.clear();
                setState(() {});
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.forward,
                    size: 18,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Skip this section',
                    style: textStyle.copyWith(
                      color: CupertinoColors.secondaryLabel,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMotherTonguePicker(BuildContext context) {
    final options = OptionTypes.motherTongueOptions;
    final currentValue =
        widget.initialData[StepConstants.motherTongue] as String? ?? '';

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 216,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CupertinoButton(
                        child: const Text('Done'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    magnification: 1.22,
                    squeeze: 1.2,
                    useMagnifier: true,
                    itemExtent: 32.0,
                    scrollController: FixedExtentScrollController(
                      initialItem: options.indexOf(currentValue),
                    ),
                    onSelectedItemChanged: (int selectedItem) {
                      setState(() {
                        _updateField(
                          StepConstants.motherTongue,
                          options[selectedItem].isEmpty
                              ? null
                              : options[selectedItem],
                        );
                      });
                    },
                    children: List<Widget>.generate(options.length, (
                      int index,
                    ) {
                      return Center(
                        child: Text(
                          options[index].isEmpty
                              ? 'Prefer not to say'
                              : capitalize(options[index]),
                          style: CupertinoTheme.of(context).textTheme.textStyle,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReligionPicker(BuildContext context) {
    final options = OptionTypes.religionOptions;
    final currentValue =
        widget.initialData[StepConstants.religion] as String? ?? '';

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 216,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CupertinoButton(
                        child: const Text('Done'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    magnification: 1.22,
                    squeeze: 1.2,
                    useMagnifier: true,
                    itemExtent: 32.0,
                    scrollController: FixedExtentScrollController(
                      initialItem: options.indexOf(currentValue),
                    ),
                    onSelectedItemChanged: (int selectedItem) {
                      setState(() {
                        _updateField(
                          StepConstants.religion,
                          options[selectedItem].isEmpty
                              ? null
                              : options[selectedItem],
                        );
                      });
                    },
                    children: List<Widget>.generate(options.length, (
                      int index,
                    ) {
                      return Center(
                        child: Text(
                          options[index].isEmpty
                              ? 'Prefer not to say'
                              : capitalize(options[index]),
                          style: CupertinoTheme.of(context).textTheme.textStyle,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
