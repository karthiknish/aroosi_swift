import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'base_step.dart';
import 'step_constants.dart';
import '../../../../core/data/country_dial_codes.dart';

/// About Me step widget
class StepAboutMe extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final OnDataUpdate? onDataUpdate;
  final GlobalKey<FormState>? formKey;

  const StepAboutMe({
    super.key,
    this.initialData = const {},
    this.onDataUpdate,
    this.formKey,
  });

  @override
  State<StepAboutMe> createState() => _StepAboutMeState();
}

class _StepAboutMeState extends State<StepAboutMe> {
  late final TextEditingController _aboutMeCtrl;
  late final TextEditingController _phoneCtrl;

  String? _selectedDialCode;
  bool _dialCodeInitialized = false;

  @override
  void initState() {
    super.initState();
    _aboutMeCtrl = TextEditingController(
      text: widget.initialData[StepConstants.aboutMe] as String? ?? '',
    );
    _phoneCtrl = TextEditingController(
      text: widget.initialData[StepConstants.phoneNumber] as String? ?? '',
    );
    _selectedDialCode = StepConstants.defaultDialCode;
    _initializeDialCode();
  }

  @override
  void dispose() {
    _aboutMeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _initializeDialCode() {
    if (_phoneCtrl.text.isNotEmpty && !_dialCodeInitialized) {
      final existing = _phoneCtrl.text.trim();
      final match = RegExp(r'^\+(\d{1,4})').firstMatch(existing);
      if (match != null) {
        final group = match.group(1);
        if (group != null) {
          final code = '+$group';
          final found = kCountryDialCodes.firstWhere(
            (c) => c.dialCode == code,
            orElse: () => kCountryDialCodes.firstWhere(
              (c) => c.dialCode == StepConstants.defaultDialCode,
            ),
          );
          _selectedDialCode = found.dialCode;
          final national = existing.substring(code.length).trim();
          if (national.isNotEmpty) {
            _phoneCtrl.text = national;
          }
        }
        _dialCodeInitialized = true;
      }
    }
  }

  void _updateField(String key, dynamic value) {
    widget.onDataUpdate?.call(key, value);
  }

  void _updateComposedPhone() {
    final local = _phoneCtrl.text.trim();
    final code = _selectedDialCode ?? '';

    if (local.isEmpty || code.isEmpty) {
      _updateField(StepConstants.phoneNumber, null);
      return;
    }

    if (local.startsWith(code)) {
      _updateField(StepConstants.phoneNumber, local);
    } else if (local.startsWith('+')) {
      _updateField(StepConstants.phoneNumber, local);
    } else {
      _updateField(StepConstants.phoneNumber, '$code$local');
    }
  }

  String? _validateAboutMe(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tell us about yourself';
    }
    if (!hasAtLeastWords(value, StepConstants.minimumAboutMeWords)) {
      return 'Write at least ${StepConstants.minimumAboutMeWords} words';
    }
    if (value.trim().length < StepConstants.minimumAboutMeLength) {
      return 'About me must be at least ${StepConstants.minimumAboutMeLength} characters';
    }
    if (value.trim().length > StepConstants.maximumAboutMeLength) {
      return 'About me must be less than ${StepConstants.maximumAboutMeLength} characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Phone number is required';

    final full = (_selectedDialCode ?? '') + raw;
    if (!isValidPhone(full)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  int _getWordCount() {
    return _aboutMeCtrl.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
  }

  int _getCharacterCount() {
    return _aboutMeCtrl.text.trim().length;
  }

  // Common utility methods
  bool hasAtLeastWords(String text, int words) {
    final tokens = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return tokens.length >= words;
  }

  bool isValidPhone(String value) {
    final normalized = normalizePhoneNumber(value);
    if (normalized == null) return false;
    return RegExp(r'^\+[1-9][\d]{9,14}$').hasMatch(normalized);
  }

  String? normalizePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final digits = cleaned.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 10 && digits.length <= 15) {
      return '+$digits';
    }
    return phone.trim();
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

  List<TextInputFormatter> get phoneFormatter => [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
  ];

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final textStyle = cupertinoTheme.textTheme.textStyle;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Me
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About me',
                style: textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: cupertinoDecoration(
                  context,
                  hasError: _validateAboutMe(_aboutMeCtrl.text) != null,
                ),
                child: cupertinoFieldPadding(
                  CupertinoTextField(
                    controller: _aboutMeCtrl,
                    placeholder:
                        'Share your story (min ${StepConstants.minimumAboutMeWords} words)',
                    placeholderStyle: textStyle.copyWith(
                      color: CupertinoColors.placeholderText,
                    ),
                    maxLines: 6,
                    minLines: 4,
                    style: textStyle,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                    ),
                    onChanged: (value) {
                      _updateField(StepConstants.aboutMe, value.trim());
                      setState(() {}); // Update word count
                    },
                  ),
                ),
              ),
              if (_validateAboutMe(_aboutMeCtrl.text) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _validateAboutMe(_aboutMeCtrl.text)!,
                    style: textStyle.copyWith(
                      color: CupertinoColors.systemRed,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              // Word count and progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getWordCount()} words / ${_getCharacterCount()} chars',
                      style: textStyle.copyWith(
                        color: CupertinoColors.secondaryLabel,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor:
                            (_getWordCount() /
                                    StepConstants.minimumAboutMeWords)
                                .clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                _getWordCount() >=
                                    StepConstants.minimumAboutMeWords
                                ? CupertinoColors.systemBlue
                                : CupertinoColors.systemOrange,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Phone Number
          Text(
            'Contact Information',
            style: textStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code',
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
                          onPressed: () => _showCountryCodePicker(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDialCode != null
                                    ? '${kCountryDialCodes.firstWhere((c) => c.dialCode == _selectedDialCode).flag}  $_selectedDialCode'
                                    : 'Select',
                                style: textStyle.copyWith(
                                  color: _selectedDialCode == null
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
              const SizedBox(width: 8),
              Expanded(
                flex: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phone number',
                      style: textStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: cupertinoDecoration(
                        context,
                        hasError: _validatePhone(_phoneCtrl.text) != null,
                      ),
                      child: cupertinoFieldPadding(
                        CupertinoTextField(
                          controller: _phoneCtrl,
                          placeholder: 'National number',
                          placeholderStyle: textStyle.copyWith(
                            color: CupertinoColors.placeholderText,
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: phoneFormatter,
                          style: textStyle,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.transparent),
                          ),
                          onChanged: (value) {
                            _updateComposedPhone();
                          },
                        ),
                      ),
                    ),
                    if (_validatePhone(_phoneCtrl.text) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _validatePhone(_phoneCtrl.text)!,
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
                      CupertinoIcons.lock_shield,
                      size: 20,
                      color: CupertinoColors.systemBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Privacy & Security',
                      style: textStyle.copyWith(
                        color: CupertinoColors.systemBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your phone number is kept private and only used for account verification and important notifications. It will not be visible to other users.',
                  style: textStyle.copyWith(
                    color: CupertinoColors.secondaryLabel,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryCodePicker(BuildContext context) {
    final currentIndex = _selectedDialCode != null
        ? kCountryDialCodes.indexWhere((c) => c.dialCode == _selectedDialCode)
        : 0;

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
                      initialItem: currentIndex >= 0 ? currentIndex : 0,
                    ),
                    onSelectedItemChanged: (int selectedItem) {
                      setState(() {
                        _selectedDialCode =
                            kCountryDialCodes[selectedItem].dialCode;
                        _updateComposedPhone();
                      });
                    },
                    children: List<Widget>.generate(kCountryDialCodes.length, (
                      int index,
                    ) {
                      final country = kCountryDialCodes[index];
                      return Center(
                        child: Text(
                          '${country.flag}  ${country.dialCode}',
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
