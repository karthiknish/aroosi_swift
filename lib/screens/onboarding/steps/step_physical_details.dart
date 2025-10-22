import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'base_step.dart';
import 'step_constants.dart';

/// Physical Details step widget
class StepPhysicalDetails extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final OnDataUpdate? onDataUpdate;
  final GlobalKey<FormState>? formKey;

  const StepPhysicalDetails({
    super.key,
    this.initialData = const {},
    this.onDataUpdate,
    this.formKey,
  });

  @override
  State<StepPhysicalDetails> createState() => _StepPhysicalDetailsState();
}

class _StepPhysicalDetailsState extends State<StepPhysicalDetails> {
  late final TextEditingController _heightCtrl;

  @override
  void initState() {
    super.initState();
    _heightCtrl = TextEditingController(
      text: widget.initialData[StepConstants.height] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    super.dispose();
  }

  void _updateField(String key, dynamic value) {
    widget.onDataUpdate?.call(key, value);
  }

  String? _validateHeight(String? value) {
    return validateHeight(value);
  }

  String? _validateMaritalStatus(String? value) {
    return validateDropdown(value, 'Marital status');
  }

  // Common utility methods
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

  String? validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  void _showMaritalStatusPicker(BuildContext context) {
    final options = OptionTypes.maritalStatusOptions;
    final currentValue =
        widget.initialData[StepConstants.maritalStatus] as String?;

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
                      initialItem: options.indexOf(
                        currentValue ?? options.first,
                      ),
                    ),
                    onSelectedItemChanged: (int selectedItem) {
                      setState(() {
                        _updateField(
                          StepConstants.maritalStatus,
                          options[selectedItem],
                        );
                      });
                    },
                    children: options.map((option) {
                      return Center(child: Text(capitalize(option)));
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPhysicalStatusPicker(BuildContext context) {
    final options = OptionTypes.physicalStatusOptions;
    final currentValue =
        widget.initialData[StepConstants.physicalStatus] as String? ??
        StepConstants.defaultPhysicalStatus;

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
                          StepConstants.physicalStatus,
                          options[selectedItem],
                        );
                      });
                    },
                    children: options.map((option) {
                      return Center(child: Text(capitalize(option)));
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  List<TextInputFormatter> get numericFormatter => [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  ];

  String _convertHeightToFeetInches(String cmString) {
    final cm = num.tryParse(cmString);
    if (cm == null) return '';

    final totalInches = (cm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;

    return "$feet'$inches\"";
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
          // Height
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Height (cm)',
                style: textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: cupertinoDecoration(
                  context,
                  hasError: _validateHeight(_heightCtrl.text) != null,
                ),
                child: cupertinoFieldPadding(
                  CupertinoTextField(
                    controller: _heightCtrl,
                    placeholder:
                        '${StepConstants.minimumHeight} - ${StepConstants.maximumHeight}',
                    placeholderStyle: textStyle.copyWith(
                      color: CupertinoColors.placeholderText,
                    ),
                    style: textStyle,
                    keyboardType: TextInputType.number,
                    inputFormatters: numericFormatter,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                    ),
                    onChanged: (value) {
                      _updateField(StepConstants.height, value.trim());
                      setState(() {}); // Update feet/inches display
                    },
                  ),
                ),
              ),
              if (_validateHeight(_heightCtrl.text) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _validateHeight(_heightCtrl.text)!,
                    style: textStyle.copyWith(
                      color: CupertinoColors.systemRed,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (_heightCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Also ${_convertHeightToFeetInches(_heightCtrl.text)}',
                    style: textStyle.copyWith(
                      color: CupertinoColors.secondaryLabel,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Marital Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Marital status',
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
                      _validateMaritalStatus(
                        widget.initialData[StepConstants.maritalStatus]
                            as String?,
                      ) !=
                      null,
                ),
                child: cupertinoFieldPadding(
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showMaritalStatusPicker(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          capitalize(
                            widget.initialData[StepConstants.maritalStatus]
                                    as String? ??
                                'Select',
                          ),
                          style: textStyle.copyWith(
                            color:
                                widget.initialData[StepConstants
                                        .maritalStatus] ==
                                    null
                                ? CupertinoColors.placeholderText
                                : CupertinoColors.label,
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
          const SizedBox(height: 16),

          // Physical Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Physical status',
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
                    onPressed: () => _showPhysicalStatusPicker(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          capitalize(
                            widget.initialData[StepConstants.physicalStatus]
                                    as String? ??
                                StepConstants.defaultPhysicalStatus,
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
          const SizedBox(height: 16),

          // Information card
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
                      CupertinoIcons.info_circle,
                      size: 20,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'About your physical information',
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
                  'This information helps us find compatible matches. Height and physical status are visible to other users.',
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
