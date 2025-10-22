import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'base_step.dart';
import 'step_constants.dart';

/// Location step widget
class StepLocation extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final OnDataUpdate? onDataUpdate;
  final GlobalKey<FormState>? formKey;

  const StepLocation({
    super.key,
    this.initialData = const {},
    this.onDataUpdate,
    this.formKey,
  });

  @override
  State<StepLocation> createState() => _StepLocationState();
}

class _StepLocationState extends State<StepLocation> {
  late final TextEditingController _cityCtrl;

  @override
  void initState() {
    super.initState();
    _cityCtrl = TextEditingController(
      text: widget.initialData[StepConstants.city] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  void _updateField(String key, dynamic value) {
    widget.onDataUpdate?.call(key, value);
  }

  String? _validateCity(String? value) {
    return validateMinLength(value, StepConstants.minimumCityLength, 'city');
  }

  

  // Common utility methods
  String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  String? validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  BoxDecoration cupertinoDecoration(BuildContext context, {bool hasError = false}) {
    return BoxDecoration(
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      border: Border.all(
        color: hasError 
          ? CupertinoColors.systemRed 
          : CupertinoTheme.of(context).primaryContrastingColor.withValues(alpha: 0.18),
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
          // Country
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Country',
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
                    onPressed: () => _showCountryPicker(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.initialData[StepConstants.country] as String? ??
                          StepConstants.defaultCountry,
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

          // City
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'City',
                style: textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: cupertinoDecoration(
                  context, 
                  hasError: _validateCity(_cityCtrl.text) != null
                ),
                child: cupertinoFieldPadding(
                  CupertinoTextField(
                    controller: _cityCtrl,
                    placeholder: 'Enter your city',
                    placeholderStyle: textStyle.copyWith(
                      color: CupertinoColors.placeholderText,
                    ),
                    style: textStyle,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\-]')),
                    ],
                    onChanged: (value) =>
                        _updateField(StepConstants.city, value.trim()),
                  ),
                ),
              ),
              if (_validateCity(_cityCtrl.text) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _validateCity(_cityCtrl.text)!,
                    style: textStyle.copyWith(
                      color: CupertinoColors.systemRed,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Location helper text
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
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  size: 20,
                  color: CupertinoColors.systemBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your location helps us find matches near you. This information is kept private and only shown to your matches.',
                    style: textStyle.copyWith(
                      color: CupertinoColors.secondaryLabel,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    final options = OptionTypes.countryOptions;
    final currentValue = widget.initialData[StepConstants.country] as String? ?? 
                        StepConstants.defaultCountry;
    
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
                        _updateField(StepConstants.country, options[selectedItem]);
                      });
                    },
                    children: List<Widget>.generate(options.length, (int index) {
                      return Center(
                        child: Text(
                          options[index],
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
