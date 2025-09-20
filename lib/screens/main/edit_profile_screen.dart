import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/profiles/profiles_repository.dart';
import 'package:aroosi_flutter/features/profiles/profile_constants.dart';

// NOTE: The current UserProfile model is minimal (fullName, email, plan, etc.).
// Many detailed demographic fields used in aroosi-mobile are NOT yet part of
// this Flutter model. The form below collects a superset so we can send partial
// updates once backend & model expand. For now, bootstrap only supported fields
// (fullName) and leave others empty. Future work: extend UserProfile and hydrate
// initial values for all editable properties.

/// Full parity edit profile screen (subset of aroosi-mobile fields) with
/// grouped sections. This intentionally keeps UI simple (no chips/select modals)
/// to ship functionality quickly; future enhancement can replace basic inputs
/// with custom pickers & multi-selects.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'UK');
  final _heightFeetCtrl = TextEditingController();
  final _heightInchesCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _annualIncomeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _religionCtrl = TextEditingController();
  final _motherTongueCtrl = TextEditingController();
  final _ethnicityCtrl = TextEditingController();
  final _partnerAgeMinCtrl = TextEditingController();
  final _partnerAgeMaxCtrl = TextEditingController();
  final _partnerCitiesCtrl = TextEditingController();
  final _interestInputCtrl = TextEditingController();

  // Multi-select sets
  final Set<String> _partnerCities = {};
  final Set<String> _interests = {};

  // Simple dropdown value holders
  String? _gender; // male/female
  String? _preferredGender; // male/female/any
  String? _maritalStatus; // single, divorced, widowed
  String? _diet; // veg, non-veg, vegan, halal
  String? _smoking; // no, occasionally, yes
  String? _drinking; // no, occasionally, socially
  String? _physicalStatus; // normal, athletic, plus-size etc.
  String? _profileFor; // self, sibling, child
  bool _hideFromFreeUsers = false;

  DateTime? _dob; // dateOfBirth
  bool _saving = false;
  bool _hasBootstrapped = false;

  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure profile data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapFromProfile();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for auth state changes and refresh profile data
    final authState = ref.watch(authControllerProvider);
    if (authState.profile != null && !_hasBootstrapped) {
      _bootstrapFromProfile();
      _hasBootstrapped = true;
    }
  }

   void _bootstrapFromProfile() {
     final authState = ref.read(authControllerProvider);
     final p = authState.profile;

     if (p == null) {
       // Profile not loaded yet, try to refresh it
       ref.read(authControllerProvider.notifier).refreshProfileOnly();
       return;
     }

     _hasBootstrapped = true;

    _nameCtrl.text = p.fullName ?? '';
    _aboutCtrl.text = p.aboutMe ?? '';
    _cityCtrl.text = p.city ?? '';
    _countryCtrl.text = p.country ?? _countryCtrl.text;
    if (p.height != null && p.height! > 0) {
      // convert cm -> feet/inches for display
      final inchesTotal = (p.height! / 2.54);
      final feet = inchesTotal ~/ 12;
      final inches = (inchesTotal - feet * 12).round();
      _heightFeetCtrl.text = feet.toString();
      _heightInchesCtrl.text = inches.toString();
    }
    _educationCtrl.text = p.education ?? '';
    _occupationCtrl.text = p.occupation ?? '';
    _annualIncomeCtrl.text = p.annualIncome?.toString() ?? '';
    _phoneCtrl.text = p.phoneNumber ?? '';
    _religionCtrl.text = p.religion ?? '';
    _motherTongueCtrl.text = p.motherTongue ?? '';
    _ethnicityCtrl.text = p.ethnicity ?? '';
    _gender = p.gender;
    _preferredGender = p.preferredGender;
    _maritalStatus = p.maritalStatus;
    _diet = p.diet;
    _smoking = p.smoking;
    _drinking = p.drinking;
    _physicalStatus = p.physicalStatus;
    _profileFor = p.profileFor;
    _hideFromFreeUsers = p.hideFromFreeUsers ?? false;
    if (p.dateOfBirth != null) {
      _dob = p.dateOfBirth;
    }
    if (p.partnerPreferenceAgeMin != null) {
      _partnerAgeMinCtrl.text = p.partnerPreferenceAgeMin.toString();
    }
    if (p.partnerPreferenceAgeMax != null) {
      _partnerAgeMaxCtrl.text = p.partnerPreferenceAgeMax.toString();
    }
    if (p.partnerPreferenceCity != null &&
        p.partnerPreferenceCity!.isNotEmpty) {
      _partnerCities
        ..clear()
        ..addAll(p.partnerPreferenceCity!);
    }
    if (p.interests != null && p.interests!.isNotEmpty) {
      _interests
        ..clear()
        ..addAll(p.interests!);
    }
  }

  int? _toCentimeters(String feetStr, String inchesStr) {
    if (feetStr.isEmpty) return null;
    final feet = int.tryParse(feetStr) ?? 0;
    final inches = int.tryParse(inchesStr) ?? 0;
    if (feet <= 0 && inches <= 0) return null;
    final totalInches = feet * 12 + inches;
    return (totalInches * 2.54).round();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 25, now.month, now.day);
    final firstDate = DateTime(now.year - 80);
    final lastDate = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  List<String> _validateFormLevel() {
    final errors = <String>[];
    // Age preference checks
    final minAge = int.tryParse(_partnerAgeMinCtrl.text);
    final maxAge = int.tryParse(_partnerAgeMaxCtrl.text);
    if (minAge != null && (minAge < 18 || minAge > 80)) {
      errors.add('Partner min age must be between 18 and 80');
    }
    if (maxAge != null && (maxAge < 18 || maxAge > 80)) {
      errors.add('Partner max age must be between 18 and 80');
    }
    if (minAge != null && maxAge != null && minAge > maxAge) {
      errors.add('Partner min age cannot exceed max age');
    }
    // Height sanity
    final feet = int.tryParse(_heightFeetCtrl.text);
    final inches = int.tryParse(_heightInchesCtrl.text);
    if ((feet != null && feet > 0) || (inches != null && inches > 0)) {
      if (feet == null || feet < 3 || feet > 7) {
        errors.add('Height feet must be between 3 and 7');
      }
      if (inches != null && (inches < 0 || inches > 11)) {
        errors.add('Height inches must be between 0 and 11');
      }
    }
    return errors;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final formErrors = _validateFormLevel();
    if (formErrors.isNotEmpty) {
      ToastService.instance.error(formErrors.join('\n'));
      return;
    }
    setState(() => _saving = true);

    // Build update map (only include non-empty fields)
    final Map<String, dynamic> updates = {};
    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      updates[key] = value;
    }

    put('fullName', _nameCtrl.text.trim());
    put('aboutMe', _aboutCtrl.text.trim());
    put('city', _cityCtrl.text.trim());
    put('country', _countryCtrl.text.trim());
    final cm = _toCentimeters(
      _heightFeetCtrl.text.trim(),
      _heightInchesCtrl.text.trim(),
    );
    if (cm != null) put('height', cm); // RN stores height numeric (cm)
    put('education', _educationCtrl.text.trim());
    put('occupation', _occupationCtrl.text.trim());
    if (_annualIncomeCtrl.text.trim().isNotEmpty) {
      final income = int.tryParse(_annualIncomeCtrl.text.trim());
      if (income != null) put('annualIncome', income);
    }
    put('phoneNumber', _phoneCtrl.text.trim());
    put('religion', _religionCtrl.text.trim());
    put('motherTongue', _motherTongueCtrl.text.trim());
    put('ethnicity', _ethnicityCtrl.text.trim());
    put('gender', _gender);
    put('preferredGender', _preferredGender);
    put('maritalStatus', _maritalStatus);
    put('diet', _diet);
    put('smoking', _smoking);
    put('drinking', _drinking);
    put('physicalStatus', _physicalStatus);
    put('profileFor', _profileFor);
    put('hideFromFreeUsers', _hideFromFreeUsers);
    if (_dob != null) {
      put('dateOfBirth', _dob!.toIso8601String());
    }
    if (_partnerAgeMinCtrl.text.isNotEmpty) {
      final v = int.tryParse(_partnerAgeMinCtrl.text);
      if (v != null) put('partnerPreferenceAgeMin', v);
    }
    if (_partnerAgeMaxCtrl.text.isNotEmpty) {
      final v = int.tryParse(_partnerAgeMaxCtrl.text);
      if (v != null) put('partnerPreferenceAgeMax', v);
    }
    if (_partnerCities.isNotEmpty) {
      put('partnerPreferenceCity', _partnerCities.toList());
    }
    if (_interests.isNotEmpty) {
      put('interests', _interests.toList());
    }

    try {
      await ref.read(profilesRepositoryProvider).updateProfile(updates);
      await ref.read(authControllerProvider.notifier).refreshProfileOnly();
      if (mounted) {
        ToastService.instance.success('Profile updated');
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        ToastService.instance.error('Failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aboutCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _heightFeetCtrl.dispose();
    _heightInchesCtrl.dispose();
    _educationCtrl.dispose();
    _occupationCtrl.dispose();
    _annualIncomeCtrl.dispose();
    _phoneCtrl.dispose();
    _religionCtrl.dispose();
    _motherTongueCtrl.dispose();
    _ethnicityCtrl.dispose();
    _partnerAgeMinCtrl.dispose();
    _partnerAgeMaxCtrl.dispose();
    _partnerCitiesCtrl.dispose();
    _interestInputCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: const OutlineInputBorder(),
    isDense: true,
  );

  Widget _sectionCard(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...children.map(
            (c) =>
                Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
          ),
        ],
      ),
    );
  }

  Widget _chipSelector({
    required String label,
    required List<String> options,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final selected = o == value;
            return SizedBox(
              height: 32, // Fixed height to prevent sizing issues
              child: ChoiceChip(
                label: Text(o),
                selected: selected,
                onSelected: (_) => onChanged(selected ? null : o),
                selectedColor: theme.colorScheme.primaryContainer,
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // (Old dropdown helper removed; replaced by chip selector UI.)

  String _dobLabel() => _dob == null
      ? 'Select date of birth'
      : _dob!.toIso8601String().split('T').first;

  void _addPartnerCity(String city) {
    final c = city.trim();
    if (c.isEmpty) return;
    setState(() => _partnerCities.add(c));
  }

  void _removePartnerCity(String city) {
    setState(() => _partnerCities.remove(city));
  }

  void _addInterest(String interest) {
    final i = interest.trim();
    if (i.isEmpty) return;
    setState(() => _interests.add(i.toLowerCase()));
  }

  void _removeInterest(String interest) {
    setState(() => _interests.remove(interest));
  }

  Widget _chipsEditable({
    required String label,
    required Set<String> values,
    required void Function(String) onAdd,
    required void Function(String) onRemove,
    TextEditingController? inputController,
    String hint = 'Add item',
    List<String>? suggestions,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...values.map(
              (v) => SizedBox(
                height: 32, // Fixed height to prevent sizing issues
                child: InputChip(label: Text(v), onDeleted: () => onRemove(v)),
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: inputController,
                decoration: InputDecoration(
                  hintText: hint,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  onAdd(value);
                  inputController?.clear();
                },
              ),
            ),
          ],
        ),
        if (suggestions != null && suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestions.take(12).map((s) {
              final already = values.contains(s);
              return ActionChip(
                label: Text(s),
                backgroundColor: already
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                onPressed: already
                    ? null
                    : () {
                        onAdd(s);
                      },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Trigger bootstrap when profile becomes available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.profile != null && !_hasBootstrapped) {
        _bootstrapFromProfile();
      }
    });

    // Show loading if profile is not loaded yet
    if (authState.loading && authState.profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error if there's an error loading profile
    if (authState.error != null && authState.profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading profile: ${authState.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).refreshProfileOnly();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final saveBtn = FilledButton.icon(
      onPressed: _saving ? null : _save,
      icon: _saving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save),
      label: Text(_saving ? 'Saving...' : 'Save'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionCard('Basic', [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _dec('Full Name'),
                      validator: _required,
                    ),
                    GestureDetector(
                      onTap: _pickDob,
                      child: InputDecorator(
                        decoration: _dec('Date of Birth'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_dobLabel()),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),
                    _chipSelector(
                      label: 'Gender',
                      options: genderOptions,
                      value: _gender,
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                    _chipSelector(
                      label: 'Preferred Gender',
                      options: preferredGenderOptions,
                      value: _preferredGender,
                      onChanged: (v) => setState(() => _preferredGender = v),
                    ),
                    TextFormField(
                      controller: _aboutCtrl,
                      decoration: _dec('About Me'),
                      maxLines: 4,
                    ),
                  ]),
                  _sectionCard('Location', [
                    TextFormField(
                      controller: _cityCtrl,
                      decoration: _dec('City'),
                      validator: _required,
                    ),
                    TextFormField(
                      controller: _countryCtrl,
                      decoration: _dec('Country'),
                      validator: _required,
                    ),
                  ]),
                  _sectionCard('Physical', [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _heightFeetCtrl,
                            decoration: _dec('Height (ft)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _heightInchesCtrl,
                            decoration: _dec('Height (in)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    _chipSelector(
                      label: 'Marital Status',
                      options: maritalStatusOptions,
                      value: _maritalStatus,
                      onChanged: (v) => setState(() => _maritalStatus = v),
                    ),
                    _chipSelector(
                      label: 'Physical Status',
                      options: physicalStatusOptions,
                      value: _physicalStatus,
                      onChanged: (v) => setState(() => _physicalStatus = v),
                    ),
                    _chipSelector(
                      label: 'Diet',
                      options: dietOptions,
                      value: _diet,
                      onChanged: (v) => setState(() => _diet = v),
                    ),
                    _chipSelector(
                      label: 'Smoking',
                      options: smokingOptions,
                      value: _smoking,
                      onChanged: (v) => setState(() => _smoking = v),
                    ),
                    _chipSelector(
                      label: 'Drinking',
                      options: drinkingOptions,
                      value: _drinking,
                      onChanged: (v) => setState(() => _drinking = v),
                    ),
                  ]),
                  _sectionCard('Professional', [
                    TextFormField(
                      controller: _educationCtrl,
                      decoration: _dec('Education'),
                    ),
                    TextFormField(
                      controller: _occupationCtrl,
                      decoration: _dec('Occupation'),
                    ),
                    TextFormField(
                      controller: _annualIncomeCtrl,
                      decoration: _dec('Annual Income (number)'),
                      keyboardType: TextInputType.number,
                    ),
                  ]),
                  _sectionCard('Cultural', [
                    TextFormField(
                      controller: _religionCtrl,
                      decoration: _dec('Religion'),
                    ),
                    TextFormField(
                      controller: _motherTongueCtrl,
                      decoration: _dec('Mother Tongue'),
                    ),
                    TextFormField(
                      controller: _ethnicityCtrl,
                      decoration: _dec('Ethnicity'),
                    ),
                    _chipSelector(
                      label: 'Profile For',
                      options: profileForOptions,
                      value: _profileFor,
                      onChanged: (v) => setState(() => _profileFor = v),
                    ),
                  ]),
                  _sectionCard('Contact', [
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: _dec('Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                  ]),
                  _sectionCard('Partner Preferences', [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _partnerAgeMinCtrl,
                            decoration: _dec('Age Min'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _partnerAgeMaxCtrl,
                            decoration: _dec('Age Max'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    _chipsEditable(
                      label: 'Preferred Cities',
                      values: _partnerCities,
                      onAdd: _addPartnerCity,
                      onRemove: _removePartnerCity,
                      inputController: _partnerCitiesCtrl,
                      hint: 'Add city',
                    ),
                  ]),
                  _sectionCard('Interests', [
                    _chipsEditable(
                      label: 'Interests',
                      values: _interests,
                      onAdd: _addInterest,
                      onRemove: _removeInterest,
                      inputController: _interestInputCtrl,
                      hint: 'Add interest',
                      suggestions: defaultInterestSuggestions,
                    ),
                  ]),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hide From Free Users'),
                    value: _hideFromFreeUsers,
                    onChanged: (v) => setState(() => _hideFromFreeUsers = v),
                  ),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: saveBtn),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
