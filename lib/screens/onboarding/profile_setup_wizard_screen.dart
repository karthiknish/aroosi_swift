import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _currentStepIndex = 0;

  final Map<String, dynamic> _data = <String, dynamic>{
    'country': 'UK',
    'profileFor': 'self',
  };

  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _educationCtrl = TextEditingController();
  final TextEditingController _occupationCtrl = TextEditingController();
  final TextEditingController _annualIncomeCtrl = TextEditingController();
  final TextEditingController _ethnicityCtrl = TextEditingController();
  final TextEditingController _aboutMeCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _partnerMinAgeCtrl = TextEditingController();
  final TextEditingController _partnerMaxAgeCtrl = TextEditingController();

  DateTime? _dateOfBirth;

  static const List<String> _genderOptions = <String>[
    'male',
    'female',
    'other',
  ];
  static const List<String> _preferredGenderOptions = <String>[
    'male',
    'female',
    'both',
    'other',
  ];
  static const List<String> _maritalStatusOptions = <String>[
    'single',
    'divorced',
    'widowed',
    'annulled',
    'separated',
  ];
  static const List<String> _dietOptions = <String>[
    'vegetarian',
    'non-vegetarian',
    'halal',
    'other',
    'vegan',
    'kosher',
  ];
  static const List<String> _smokingDrinkingOptions = <String>[
    'no',
    'occasionally',
    'yes',
  ];
  static const List<String> _physicalStatusOptions = <String>[
    'normal',
    'differently-abled',
    'other',
  ];
  static const List<String> _profileForOptions = <String>[
    'self',
    'friend',
    'family',
  ];
  static const List<String> _religionOptions = <String>[
    '',
    'islam',
    'christianity',
    'hinduism',
    'sikhism',
    'judaism',
    'other',
  ];
  static const List<String> _motherTongueOptions = <String>[
    '',
    'pashto',
    'dari',
    'urdu',
    'english',
    'farsi',
    'hindi',
    'other',
  ];
  static const List<String> _countries = <String>[
    'UK',
    'USA',
    'Canada',
    'Germany',
    'France',
    'Other',
  ];

  static const List<Map<String, String>> _steps = <Map<String, String>>[
    {'title': 'Basic Info', 'subtitle': 'Tell us about yourself'},
    {'title': 'Location', 'subtitle': 'Where are you based?'},
    {'title': 'Physical Details', 'subtitle': 'Your physical attributes'},
    {'title': 'Professional', 'subtitle': 'Your career & education'},
    {'title': 'Cultural', 'subtitle': 'Your cultural background'},
    {'title': 'About Me', 'subtitle': 'Describe yourself'},
    {'title': 'Lifestyle', 'subtitle': 'Your preferences'},
    {'title': 'Photos', 'subtitle': 'Add your profile photos (optional)'},
  ];

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _cityCtrl.dispose();
    _educationCtrl.dispose();
    _occupationCtrl.dispose();
    _annualIncomeCtrl.dispose();
    _ethnicityCtrl.dispose();
    _aboutMeCtrl.dispose();
    _phoneCtrl.dispose();
    _heightCtrl.dispose();
    _partnerMinAgeCtrl.dispose();
    _partnerMaxAgeCtrl.dispose();
    super.dispose();
  }

  int? _ageFromDob(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    final hadBirthday =
        (now.month > dob.month) ||
        (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) age -= 1;
    return age;
  }

  bool _isValidPhone(String value) {
    final normalized = value.replaceAll(' ', '');
    return RegExp(r'^[+]?[1-9][\d]{9,14}$').hasMatch(normalized);
  }

  bool _hasAtLeastWords(String text, int words) {
    final tokens = text
        .trim()
        .split(RegExp(r'\s+'))
        .map(
          (w) => w.replaceAll(RegExp(r'^[^A-Za-z0-9]+|[^A-Za-z0-9]+\\$'), ''),
        )
        .where((w) => w.isNotEmpty)
        .toList();
    return tokens.length >= words;
  }

  void _onNext() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      if (_currentStepIndex < _steps.length - 1) {
        setState(() => _currentStepIndex += 1);
      } else {
        ToastService.instance.success('Profile info collected.');
        context.push('/onboarding/checklist');
      }
    }
  }

  void _onBack() {
    if (_currentStepIndex > 0) setState(() => _currentStepIndex -= 1);
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final step = _steps[_currentStepIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Create Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          step['subtitle'] ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: (_currentStepIndex + 1) / _steps.length,
          minHeight: 6,
        ),
        const SizedBox(height: 8),
        Text(
          '${_currentStepIndex + 1} of ${_steps.length}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label, {String? hint}) =>
      InputDecoration(labelText: label, hintText: hint);

  String? _validateRequired(String? value, String label, {int? minLen}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    if (minLen != null && value.trim().length < minLen)
      return '$label must be at least $minLen characters';
    return null;
  }

  Widget _stepBasicInfo(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium;
    final age = _ageFromDob(_dateOfBirth);
    return Column(
      children: [
        TextFormField(
          controller: _fullNameCtrl,
          decoration: _decoration('Full name'),
          validator: (v) => _validateRequired(v, 'Full name', minLen: 2),
          onSaved: (v) => _data['fullName'] = v?.trim(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: _decoration('Gender'),
                value: (_data['gender'] as String?),
                items: _genderOptions
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(_capitalize(g), style: textStyle),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _data['gender'] = v),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Gender is required' : null,
                style: textStyle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: _decoration('Looking for'),
                value: (_data['preferredGender'] as String?),
                items: _preferredGenderOptions
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(_capitalize(g), style: textStyle),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _data['preferredGender'] = v),
                validator: (v) =>
                    v == null || v.isEmpty ? 'This field is required' : null,
                style: textStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                readOnly: true,
                decoration: _decoration(
                  'Date of birth',
                  hint: 'Select date',
                ).copyWith(suffixIcon: const Icon(Icons.calendar_today)),
                controller: TextEditingController(
                  text: _dateOfBirth == null
                      ? ''
                      : '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
                ),
                validator: (_) {
                  if (_dateOfBirth == null) return 'Date of birth is required';
                  final a = _ageFromDob(_dateOfBirth);
                  if (a == null || a < 18 || a > 120)
                    return 'You must be between 18 and 120 years old';
                  return null;
                },
                onTap: () async {
                  final now = DateTime.now();
                  final first = DateTime(now.year - 120, now.month, now.day);
                  final last = DateTime(now.year - 18, now.month, now.day);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: last,
                    firstDate: first,
                    lastDate: last,
                  );
                  if (picked != null) setState(() => _dateOfBirth = picked);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: _decoration('Religion (optional)'),
                value: (_data['religion'] as String?) ?? '',
                items: _religionOptions
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(_labelOrEmpty(r), style: textStyle),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(
                  () => _data['religion'] = (v ?? '').isEmpty ? null : v,
                ),
                style: textStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: _decoration('Mother tongue (optional)'),
                value: (_data['motherTongue'] as String?) ?? '',
                items: _motherTongueOptions
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(_labelOrEmpty(r), style: textStyle),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(
                  () => _data['motherTongue'] = (v ?? '').isEmpty ? null : v,
                ),
                style: textStyle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _ethnicityCtrl,
                decoration: _decoration(
                  'Ethnicity (optional)',
                  hint: 'e.g., British Afghan',
                ),
                onSaved: (v) => _data['ethnicity'] = (v ?? '').trim().isEmpty
                    ? null
                    : v?.trim(),
              ),
            ),
          ],
        ),
        if (age != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Age: $age',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _stepLocation(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: _decoration('Country'),
          value: (_data['country'] as String?) ?? 'UK',
          items: _countries
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: textStyle),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _data['country'] = v),
          validator: (v) =>
              v == null || v.isEmpty ? 'Country is required' : null,
          style: textStyle,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cityCtrl,
          decoration: _decoration('City'),
          validator: (v) => _validateRequired(v, 'City', minLen: 2),
          onSaved: (v) => _data['city'] = v?.trim(),
        ),
      ],
    );
  }

  Widget _stepPhysicalDetails(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Column(
      children: [
        TextFormField(
          controller: _heightCtrl,
          decoration: _decoration('Height (cm)', hint: '100 - 250'),
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Height is required';
            final num? n = num.tryParse(v);
            if (n == null || n < 100 || n > 250)
              return 'Enter a valid height (100-250cm)';
            return null;
          },
          onSaved: (v) => _data['height'] = num.tryParse(v!.trim()),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: _decoration('Marital status'),
          value: (_data['maritalStatus'] as String?),
          items: _maritalStatusOptions
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(_capitalize(s), style: textStyle),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _data['maritalStatus'] = v),
          validator: (v) =>
              v == null || v.isEmpty ? 'Marital status is required' : null,
          style: textStyle,
        ),
      ],
    );
  }

  Widget _stepProfessional(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _educationCtrl,
          decoration: _decoration('Education'),
          validator: (v) => _validateRequired(v, 'Education', minLen: 2),
          onSaved: (v) => _data['education'] = v?.trim(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _occupationCtrl,
          decoration: _decoration('Occupation'),
          validator: (v) => _validateRequired(v, 'Occupation', minLen: 2),
          onSaved: (v) => _data['occupation'] = v?.trim(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _annualIncomeCtrl,
          decoration: _decoration(
            'Annual income (£) (optional)',
            hint: 'e.g., 50000',
          ),
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final num? n = num.tryParse(v.trim());
            if (n == null || n < 0 || n > 1000000)
              return 'Enter a valid amount';
            return null;
          },
          onSaved: (v) {
            final num? n = v == null || v.trim().isEmpty
                ? null
                : num.tryParse(v.trim());
            _data['annualIncome'] = n;
          },
        ),
      ],
    );
  }

  Widget _stepCultural(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: _decoration('Mother tongue (optional)'),
          value: (_data['motherTongue'] as String?),
          items: _motherTongueOptions
              .where((e) => e.isNotEmpty)
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(_capitalize(r), style: textStyle),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _data['motherTongue'] = v),
          style: textStyle,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _ethnicityCtrl,
          decoration: _decoration(
            'Ethnicity (optional)',
            hint: 'e.g., British Afghan',
          ),
          onSaved: (v) =>
              _data['ethnicity'] = (v ?? '').trim().isEmpty ? null : v?.trim(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: _decoration('Religion (optional)'),
          value: (_data['religion'] as String?),
          items: _religionOptions
              .where((e) => e.isNotEmpty)
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(_capitalize(r), style: textStyle),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _data['religion'] = v),
          style: textStyle,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: _decoration('Profile for'),
          value: (_data['profileFor'] as String?) ?? 'self',
          items: _profileForOptions
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(_capitalize(r), style: textStyle),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _data['profileFor'] = v),
          style: textStyle,
        ),
      ],
    );
  }

  Widget _stepAboutMe(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _aboutMeCtrl,
          maxLines: 6,
          decoration: _decoration(
            'About me',
            hint: 'Tell us about yourself (min 50 chars, 10+ words)',
          ),
          validator: (v) {
            final s = (v ?? '').trim();
            if (s.isEmpty) return 'About me is required';
            if (s.length < 50) return 'Must be at least 50 characters';
            if (!_hasAtLeastWords(s, 10))
              return 'Must contain at least 10 words';
            return null;
          },
          onSaved: (v) => _data['aboutMe'] = v?.trim(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneCtrl,
          decoration: _decoration('Phone number', hint: 'e.g., +447123456789'),
          keyboardType: TextInputType.phone,
          validator: (v) {
            final s = (v ?? '').trim();
            if (s.isEmpty) return 'Phone number is required';
            if (!_isValidPhone(s))
              return 'Enter a valid phone number (min 10 digits)';
            return null;
          },
          onSaved: (v) => _data['phoneNumber'] = v?.replaceAll(' ', ''),
        ),
      ],
    );
  }

  Widget _stepLifestyle(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: _decoration('Diet (optional)'),
          value: (_data['diet'] as String?),
          items: _dietOptions
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(_capitalize(s), style: textStyle),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _data['diet'] = v),
          style: textStyle,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: _decoration('Smoking (optional)'),
                value: (_data['smoking'] as String?),
                items: _smokingDrinkingOptions
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(_capitalize(s), style: textStyle),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _data['smoking'] = v),
                style: textStyle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: _decoration('Drinking (optional)'),
                value: (_data['drinking'] as String?),
                items: _smokingDrinkingOptions
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(_capitalize(s), style: textStyle),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _data['drinking'] = v),
                style: textStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: _decoration('Physical status (optional)'),
          value: (_data['physicalStatus'] as String?),
          items: _physicalStatusOptions
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(_capitalize(s), style: textStyle),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _data['physicalStatus'] = v),
          style: textStyle,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Partner age preferences (optional)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _partnerMinAgeCtrl,
                decoration: _decoration('Min age', hint: '18'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final int? n = int.tryParse(v.trim());
                  if (n == null || n < 18 || n > 120) return '18-120';
                  final int? max = int.tryParse(_partnerMaxAgeCtrl.text.trim());
                  if (max != null && n > max) return '<= Max age';
                  return null;
                },
                onSaved: (v) {
                  final int? n = (v ?? '').trim().isEmpty
                      ? null
                      : int.tryParse((v ?? '').trim());
                  _data['partnerPreferenceAgeMin'] = n;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _partnerMaxAgeCtrl,
                decoration: _decoration('Max age', hint: '120'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final int? n = int.tryParse(v.trim());
                  if (n == null || n < 18 || n > 120) return '18-120';
                  final int? min = int.tryParse(_partnerMinAgeCtrl.text.trim());
                  if (min != null && min > n) return '>= Min age';
                  return null;
                },
                onSaved: (v) {
                  final int? n = (v ?? '').trim().isEmpty
                      ? null
                      : int.tryParse((v ?? '').trim());
                  _data['partnerPreferenceAgeMax'] = n;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepPhotos(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Photo uploads are optional here. You can add photos later in your profile.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tip: Adding 3+ clear photos increases matches.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepTitle = _steps[_currentStepIndex]['title'] ?? '';

    Widget stepContent;
    switch (_currentStepIndex) {
      case 0:
        stepContent = _stepBasicInfo(context);
        break;
      case 1:
        stepContent = _stepLocation(context);
        break;
      case 2:
        stepContent = _stepPhysicalDetails(context);
        break;
      case 3:
        stepContent = _stepProfessional(context);
        break;
      case 4:
        stepContent = _stepCultural(context);
        break;
      case 5:
        stepContent = _stepAboutMe(context);
        break;
      case 6:
        stepContent = _stepLifestyle(context);
        break;
      case 7:
        stepContent = _stepPhotos(context);
        break;
      default:
        stepContent = const SizedBox.shrink();
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FadeThrough(
            delay: AppMotionDurations.fast,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: FadeSlideIn(
                        duration: AppMotionDurations.medium,
                        beginOffset: const Offset(0, 0.06),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              stepTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            stepContent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _currentStepIndex == 0 ? null : _onBack,
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _onNext,
                          child: Text(
                            _currentStepIndex == _steps.length - 1
                                ? 'Finish'
                                : 'Continue',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? '' : s.substring(0, 1).toUpperCase() + s.substring(1);
  static String _labelOrEmpty(String s) => s.isEmpty ? '—' : _capitalize(s);
}
