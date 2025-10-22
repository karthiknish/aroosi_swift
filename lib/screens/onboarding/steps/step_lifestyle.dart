import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'base_step.dart';
import 'step_constants.dart';

/// Lifestyle step widget
class StepLifestyle extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final OnDataUpdate? onDataUpdate;
  final GlobalKey<FormState>? formKey;

  const StepLifestyle({
    super.key,
    this.initialData = const {},
    this.onDataUpdate,
    this.formKey,
  });

  @override
  State<StepLifestyle> createState() => _StepLifestyleState();
}

class _StepLifestyleState extends State<StepLifestyle> {
  late final TextEditingController _partnerMinAgeCtrl;
  late final TextEditingController _partnerMaxAgeCtrl;
  late final TextEditingController _partnerCityCtrl;

  @override
  void initState() {
    super.initState();
    _partnerMinAgeCtrl = TextEditingController(
      text:
          widget.initialData[StepConstants.partnerPreferenceAgeMin]
              ?.toString() ??
          '',
    );
    _partnerMaxAgeCtrl = TextEditingController(
      text:
          widget.initialData[StepConstants.partnerPreferenceAgeMax]
              ?.toString() ??
          '',
    );

    // Initialize partner preference cities
    final cities =
        widget.initialData[StepConstants.partnerPreferenceCity]
            as List<String>?;
    if (cities != null && cities.isNotEmpty) {
      _partnerCityCtrl.text = cities.join(', ');
    } else {
      _partnerCityCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _partnerMinAgeCtrl.dispose();
    _partnerMaxAgeCtrl.dispose();
    _partnerCityCtrl.dispose();
    super.dispose();
  }

  void _updateField(String key, dynamic value) {
    widget.onDataUpdate?.call(key, value);
  }

  String? _validateMinAge(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional

    final int? minAge = int.tryParse(value.trim());
    if (minAge == null ||
        minAge < StepConstants.minimumAge ||
        minAge > StepConstants.maximumAge) {
      return 'Age must be between ${StepConstants.minimumAge}-${StepConstants.maximumAge}';
    }

    final int? maxAge = int.tryParse(_partnerMaxAgeCtrl.text.trim());
    if (maxAge != null && minAge > maxAge) {
      return 'Min age must be <= max age';
    }

    return null;
  }

  String? _validateMaxAge(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional

    final int? maxAge = int.tryParse(value.trim());
    if (maxAge == null ||
        maxAge < StepConstants.minimumAge ||
        maxAge > StepConstants.maximumAge) {
      return 'Age must be between ${StepConstants.minimumAge}-${StepConstants.maximumAge}';
    }

    final int? minAge = int.tryParse(_partnerMinAgeCtrl.text.trim());
    if (minAge != null && minAge > maxAge) {
      return 'Max age must be >= min age';
    }

    return null;
  }

  void _onDietChanged(String? value) {
    if (value == null || value.isEmpty) {
      _updateField(StepConstants.diet, null);
    } else {
      _updateField(StepConstants.diet, value);
    }
  }

  void _onSmokingChanged(String? value) {
    if (value == null || value.isEmpty) {
      _updateField(StepConstants.smoking, null);
    } else {
      _updateField(StepConstants.smoking, value);
    }
  }

  void _onDrinkingChanged(String? value) {
    if (value == null || value.isEmpty) {
      _updateField(StepConstants.drinking, null);
    } else {
      _updateField(StepConstants.drinking, value);
    }
  }

  void _onPhysicalStatusChanged(String? value) {
    if (value == null || value.isEmpty) {
      _updateField(StepConstants.physicalStatus, null);
    } else {
      _updateField(StepConstants.physicalStatus, value);
    }
  }

  void _onAgeRangeChanged() {
    final minAge = _partnerMinAgeCtrl.text.trim().isEmpty
        ? null
        : int.tryParse(_partnerMinAgeCtrl.text.trim());
    final maxAge = _partnerMaxAgeCtrl.text.trim().isEmpty
        ? null
        : int.tryParse(_partnerMaxAgeCtrl.text.trim());

    _updateField(StepConstants.partnerPreferenceAgeMin, minAge);
    _updateField(StepConstants.partnerPreferenceAgeMax, maxAge);
  }

  void _onCitiesChanged([String? value]) {
    final trimmed = (value ?? _partnerCityCtrl.text).trim();
    if (trimmed.isEmpty) {
      _updateField(StepConstants.partnerPreferenceCity, null);
    } else {
      final cities = trimmed
          .split(',')
          .map((city) => city.trim())
          .where((city) => city.isNotEmpty)
          .toList();
      _updateField(StepConstants.partnerPreferenceCity, cities);
    }
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
          // Lifestyle Preferences Header
          Text(
            'Lifestyle Preferences',
            style: textStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Diet and Physical Status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diet (optional)',
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
                          onPressed: () => _showDietPicker(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                capitalize(
                                  widget.initialData[StepConstants.diet]
                                          as String? ??
                                      'Select',
                                ),
                                style: textStyle.copyWith(
                                  color:
                                      widget.initialData[StepConstants.diet] ==
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
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Physical status (optional)',
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
                                  widget.initialData[StepConstants
                                              .physicalStatus]
                                          as String? ??
                                      'Select',
                                ),
                                style: textStyle.copyWith(
                                  color:
                                      widget.initialData[StepConstants
                                              .physicalStatus] ==
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
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Smoking Preference
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smoking preference (optional)',
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
                    onPressed: () => _showSmokingPicker(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          capitalize(
                            widget.initialData[StepConstants.smoking]
                                    as String? ??
                                'Select',
                          ),
                          style: textStyle.copyWith(
                            color:
                                widget.initialData[StepConstants.smoking] ==
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

          // Drinking Preference
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Drinking preference (optional)',
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
                    onPressed: () => _showDrinkingPicker(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          capitalize(
                            widget.initialData[StepConstants.drinking]
                                    as String? ??
                                'Select',
                          ),
                          style: textStyle.copyWith(
                            color:
                                widget.initialData[StepConstants.drinking] ==
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
          const SizedBox(height: 24),

          // Partner Preferences Header
          Text(
            'Partner Preferences (Optional)',
            style: textStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Age Range
          Text(
            'Preferred age range',
            style: textStyle.copyWith(
              color: CupertinoColors.secondaryLabel,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Min age',
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
                            _validateMinAge(_partnerMinAgeCtrl.text) != null,
                      ),
                      child: cupertinoFieldPadding(
                        CupertinoTextField(
                          controller: _partnerMinAgeCtrl,
                          placeholder: '${StepConstants.minimumAge}',
                          placeholderStyle: textStyle.copyWith(
                            color: CupertinoColors.placeholderText,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: textStyle,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.transparent),
                          ),
                          onChanged: (_) => _onAgeRangeChanged(),
                        ),
                      ),
                    ),
                    if (_validateMinAge(_partnerMinAgeCtrl.text) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _validateMinAge(_partnerMinAgeCtrl.text)!,
                          style: textStyle.copyWith(
                            color: CupertinoColors.systemRed,
                            fontSize: 12,
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
                      'Max age',
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
                            _validateMaxAge(_partnerMaxAgeCtrl.text) != null,
                      ),
                      child: cupertinoFieldPadding(
                        CupertinoTextField(
                          controller: _partnerMaxAgeCtrl,
                          placeholder: '${StepConstants.maximumAge}',
                          placeholderStyle: textStyle.copyWith(
                            color: CupertinoColors.placeholderText,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: textStyle,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.transparent),
                          ),
                          onChanged: (_) => _onAgeRangeChanged(),
                        ),
                      ),
                    ),
                    if (_validateMaxAge(_partnerMaxAgeCtrl.text) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _validateMaxAge(_partnerMaxAgeCtrl.text)!,
                          style: textStyle.copyWith(
                            color: CupertinoColors.systemRed,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preferred Cities
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preferred cities (optional)',
                style: textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: cupertinoDecoration(context),
                child: cupertinoFieldPadding(
                  CupertinoTextField(
                    controller: _partnerCityCtrl,
                    placeholder: 'e.g., London, Manchester, Birmingham',
                    placeholderStyle: textStyle.copyWith(
                      color: CupertinoColors.placeholderText,
                    ),
                    style: textStyle,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                    ),
                    onChanged: _onCitiesChanged,
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
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.heart,
                      size: 20,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'About your preferences',
                      style: textStyle.copyWith(
                        color: CupertinoColors.secondaryLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your lifestyle and partner preferences help us find compatible matches. All fields in this section are optional - you can skip them if you prefer.',
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
                // Clear all lifestyle and partner preference fields
                _updateField(StepConstants.diet, null);
                _updateField(StepConstants.smoking, null);
                _updateField(StepConstants.drinking, null);
                _updateField(StepConstants.physicalStatus, null);
                _updateField(StepConstants.partnerPreferenceAgeMin, null);
                _updateField(StepConstants.partnerPreferenceAgeMax, null);
                _updateField(StepConstants.partnerPreferenceCity, null);
                _partnerMinAgeCtrl.clear();
                _partnerMaxAgeCtrl.clear();
                _partnerCityCtrl.clear();
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

  void _showDietPicker(BuildContext context) {
    final options = OptionTypes.dietOptions;
    final currentValue = widget.initialData[StepConstants.diet] as String?;

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
                      initialItem: currentValue != null
                          ? options.indexOf(currentValue)
                          : 0,
                    ),
                    onSelectedItemChanged: (int selectedItem) {
                      setState(() {
                        _onDietChanged(options[selectedItem]);
                      });
                    },
                    children: List<Widget>.generate(options.length, (
                      int index,
                    ) {
                      return Center(
                        child: Text(
                          capitalize(options[index]),
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

  void _showPhysicalStatusPicker(BuildContext context) {
    final options = OptionTypes.physicalStatusOptions;
    final currentValue =
        widget.initialData[StepConstants.physicalStatus] as String?;

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
                      initialItem: currentValue != null
                          ? options.indexOf(currentValue)
                          : 0,
                    ),
                    onSelectedItemChanged: (int selectedItem) {
                      setState(() {
                        _onPhysicalStatusChanged(options[selectedItem]);
                      });
                    },
                    children: List<Widget>.generate(options.length, (
                      int index,
                    ) {
                      return Center(
                        child: Text(
                          capitalize(options[index]),
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

  void _showSmokingPicker(BuildContext context) {
    final options = OptionTypes.smokingDrinkingOptions;
    final currentValue = widget.initialData[StepConstants.smoking] as String?;

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
                      initialItem: currentValue != null
                          ? options.indexOf(currentValue)
                          : 0,
                    ),
                    onSelectedItemChanged: (int selectedItem) {
                      setState(() {
                        _onSmokingChanged(options[selectedItem]);
                      });
                    },
                    children: List<Widget>.generate(options.length, (
                      int index,
                    ) {
                      return Center(
                        child: Text(
                          capitalize(options[index]),
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

  void _showDrinkingPicker(BuildContext context) {
    final options = OptionTypes.smokingDrinkingOptions;
    final currentValue = widget.initialData[StepConstants.drinking] as String?;

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
                      initialItem: currentValue != null
                          ? options.indexOf(currentValue)
                          : 0,
                    ),
                    onSelectedItemChanged: (int selectedItem) {
                      setState(() {
                        _onDrinkingChanged(options[selectedItem]);
                      });
                    },
                    children: List<Widget>.generate(options.length, (
                      int index,
                    ) {
                      return Center(
                        child: Text(
                          capitalize(options[index]),
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
