import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'base_step.dart';
import 'step_constants.dart';

/// Basic Information step widget
class StepBasicInfo extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final OnDataUpdate? onDataUpdate;
  final GlobalKey<FormState>? formKey;

  const StepBasicInfo({
    super.key,
    this.initialData = const {},
    this.onDataUpdate,
    this.formKey,
  });

  @override
  State<StepBasicInfo> createState() => _StepBasicInfoState();
}

class _StepBasicInfoState extends State<StepBasicInfo> {
  late final TextEditingController _fullNameCtrl;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(
      text: widget.initialData[StepConstants.fullName] as String? ?? '',
    );

    // Initialize date of birth
    final dobString = widget.initialData[StepConstants.dateOfBirth] as String?;
    if (dobString != null) {
      _dateOfBirth = DateTime.tryParse(dobString);
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    super.dispose();
  }

  void _updateField(String key, dynamic value) {
    widget.onDataUpdate?.call(key, value);
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < StepConstants.minimumNameLength) {
      return 'Full name must be at least ${StepConstants.minimumNameLength} characters';
    }
    if (value.trim().length > StepConstants.maximumNameLength) {
      return 'Full name must be less than ${StepConstants.maximumNameLength} characters';
    }
    return null;
  }

  String? _validateDateOfBirth(DateTime? date) {
    if (date == null) return 'Date of birth is required';

    final age = _calculateAge(date);
    if (age == null ||
        age < StepConstants.minimumAge ||
        age > StepConstants.maximumAge) {
      return 'You must be between ${StepConstants.minimumAge} and ${StepConstants.maximumAge} years old';
    }
    return null;
  }

  int? _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    final hadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) age -= 1;
    return age;
  }

  // Common utility methods
  int? ageFromDob(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    final hadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) age -= 1;
    return age;
  }

  String capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String formatDob(DateTime? dob) {
    if (dob == null) return '';
    return '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
  }

  String? validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
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

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final textStyle = cupertinoTheme.textTheme.textStyle;
    final age = _dateOfBirth == null ? null : ageFromDob(_dateOfBirth!);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Full name',
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
                    controller: _fullNameCtrl,
                    placeholder: 'Enter your full name',
                    style: textStyle,
                    placeholderStyle: textStyle.copyWith(
                      color: CupertinoColors.placeholderText,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                    ),
                    onChanged: (value) =>
                        _updateField(StepConstants.fullName, value.trim()),
                  ),
                ),
              ),
              if (_validateFullName(_fullNameCtrl.text) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _validateFullName(_fullNameCtrl.text)!,
                    style: textStyle.copyWith(
                      color: CupertinoColors.systemRed,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Gender and Preferred Gender
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gender',
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
                          onPressed: () => _showGenderPicker(context, 'gender'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                capitalize(
                                  widget.initialData[StepConstants.gender]
                                          as String? ??
                                      'Select',
                                ),
                                style: textStyle.copyWith(
                                  color:
                                      widget.initialData[StepConstants
                                              .gender] ==
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
                      'Looking for',
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
                          onPressed: () =>
                              _showGenderPicker(context, 'preferredGender'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                capitalize(
                                  widget.initialData[StepConstants
                                              .preferredGender]
                                          as String? ??
                                      'Select',
                                ),
                                style: textStyle.copyWith(
                                  color:
                                      widget.initialData[StepConstants
                                              .preferredGender] ==
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

          // Date of Birth
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date of birth',
                style: textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: cupertinoDecoration(
                  context,
                  hasError: _validateDateOfBirth(_dateOfBirth) != null,
                ),
                child: cupertinoFieldPadding(
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showDatePicker(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDob(_dateOfBirth).isEmpty
                              ? 'Select date'
                              : formatDob(_dateOfBirth),
                          style: textStyle.copyWith(
                            color: _dateOfBirth == null
                                ? CupertinoColors.placeholderText
                                : CupertinoColors.label,
                          ),
                        ),
                        const Icon(CupertinoIcons.calendar, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              if (_validateDateOfBirth(_dateOfBirth) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _validateDateOfBirth(_dateOfBirth)!,
                    style: textStyle.copyWith(
                      color: CupertinoColors.systemRed,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (age != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Age: $age',
                    style: textStyle.copyWith(
                      color: CupertinoColors.secondaryLabel,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Profile For
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile for',
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
                    onPressed: () => _showProfileForPicker(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          capitalize(
                            widget.initialData[StepConstants.profileFor]
                                    as String? ??
                                StepConstants.defaultProfileFor,
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
        ],
      ),
    );
  }

  void _showGenderPicker(BuildContext context, String field) {
    final options = field == 'gender'
        ? OptionTypes.genderOptions
        : OptionTypes.preferredGenderOptions;
    final currentValue = widget.initialData[field] as String?;

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
                        _updateField(field, options[selectedItem]);
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

  void _showProfileForPicker(BuildContext context) {
    final options = OptionTypes.profileForOptions;
    final currentValue =
        widget.initialData[StepConstants.profileFor] as String? ??
        StepConstants.defaultProfileFor;

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
                          StepConstants.profileFor,
                          options[selectedItem],
                        );
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

  void _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final first = DateTime(
      now.year - StepConstants.maximumAge,
      now.month,
      now.day,
    );
    final last = DateTime(
      now.year - StepConstants.minimumAge,
      now.month,
      now.day,
    );

    final picked = await showCupertinoModalPopup<DateTime>(
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
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _dateOfBirth ?? last,
                    minimumDate: first,
                    maximumDate: last,
                    onDateTimeChanged: (DateTime newDate) {
                      _dateOfBirth = newDate;
                      _updateField(
                        StepConstants.dateOfBirth,
                        newDate.toIso8601String(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _updateField(StepConstants.dateOfBirth, picked.toIso8601String());
      });
    }
  }
}
