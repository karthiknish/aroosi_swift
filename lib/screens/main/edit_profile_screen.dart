import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/profiles/profiles_repository.dart';
import 'package:aroosi_flutter/theme/colors.dart';

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
    final authState = ref.watch(authControllerProvider);

    // Trigger bootstrap when profile becomes available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.profile != null && !_hasBootstrapped) {
        _bootstrapFromProfile();
      }
    });

    // If we haven't bootstrapped yet and profile is available, bootstrap immediately
    if (authState.profile != null && !_hasBootstrapped) {
      _bootstrapFromProfile();
    }

    // Show loading until we have profile data and have bootstrapped it
    if (authState.loading && !_hasBootstrapped) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: Container(
          color: Theme.of(context).colorScheme.surface,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading profile data...'),
              ],
            ),
          ),
        ),
      );
    }

    // If we have profile data but haven't bootstrapped yet, show loading
    if (authState.profile != null && !_hasBootstrapped) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: Container(
          color: Theme.of(context).colorScheme.surface,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparing profile data...'),
              ],
            ),
          ),
        ),
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
                  ref
                      .read(authControllerProvider.notifier)
                      .refreshProfileOnly();
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
      appBar: AppBar(title: const Text('Edit Profile')),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Full Name',
                          style: CupertinoTheme.of(context).textTheme.textStyle
                              .copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: cupertinoDecoration(context),
                          child: cupertinoFieldPadding(
                            CupertinoTextField(
                              controller: _nameCtrl,
                              placeholder: 'Enter your full name',
                              placeholderStyle: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .copyWith(
                                    color: CupertinoColors.placeholderText,
                                  ),
                              style: CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: Colors.transparent),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date of Birth',
                          style: CupertinoTheme.of(context).textTheme.textStyle
                              .copyWith(
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
                              onPressed: _pickDob,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _dobLabel(),
                                    style: CupertinoTheme.of(context)
                                        .textTheme
                                        .textStyle
                                        .copyWith(
                                          color: _dob == null
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
                      ],
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About Me',
                          style: CupertinoTheme.of(context).textTheme.textStyle
                              .copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: cupertinoDecoration(context),
                          child: cupertinoFieldPadding(
                            CupertinoTextField(
                              controller: _aboutCtrl,
                              placeholder: 'Tell us about yourself',
                              placeholderStyle: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .copyWith(
                                    color: CupertinoColors.placeholderText,
                                  ),
                              style: CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle,
                              maxLines: 4,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: Colors.transparent),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
                  _sectionCard('Location', [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'City',
                          style: CupertinoTheme.of(context).textTheme.textStyle
                              .copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: cupertinoDecoration(context),
                          child: cupertinoFieldPadding(
                            CupertinoTextField(
                              controller: _cityCtrl,
                              placeholder: 'Enter your city',
                              placeholderStyle: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .copyWith(
                                    color: CupertinoColors.placeholderText,
                                  ),
                              style: CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: Colors.transparent),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Country',
                          style: CupertinoTheme.of(context).textTheme.textStyle
                              .copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: cupertinoDecoration(context),
                          child: cupertinoFieldPadding(
                            CupertinoTextField(
                              controller: _countryCtrl,
                              placeholder: 'Enter your country',
                              placeholderStyle: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .copyWith(
                                    color: CupertinoColors.placeholderText,
                                  ),
                              style: CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: Colors.transparent),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
                  _sectionCard('Physical', [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: cupertinoDecoration(context),
                            child: cupertinoFieldPadding(
                              CupertinoTextField(
                                controller: _heightFeetCtrl,
                                placeholder: 'Height (ft)',
                                keyboardType: TextInputType.number,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(color: Colors.transparent),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: cupertinoDecoration(context),
                            child: cupertinoFieldPadding(
                              CupertinoTextField(
                                controller: _heightInchesCtrl,
                                placeholder: 'Height (in)',
                                keyboardType: TextInputType.number,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(color: Colors.transparent),
                                ),
                              ),
                            ),
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
                    Container(
                      decoration: cupertinoDecoration(context),
                      child: cupertinoFieldPadding(
                        CupertinoTextField(
                          controller: _educationCtrl,
                          placeholder: 'Education',
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: cupertinoDecoration(context),
                      child: cupertinoFieldPadding(
                        CupertinoTextField(
                          controller: _occupationCtrl,
                          placeholder: 'Occupation',
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: cupertinoDecoration(context),
                      child: cupertinoFieldPadding(
                        CupertinoTextField(
                          controller: _annualIncomeCtrl,
                          placeholder: 'Annual Income (number)',
                          keyboardType: TextInputType.number,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  _sectionCard('Cultural', [
                    Container(
                      decoration: cupertinoDecoration(context),
                      child: cupertinoFieldPadding(
                        CupertinoTextField(
                          controller: _religionCtrl,
                          placeholder: 'Religion',
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: cupertinoDecoration(context),
                      child: cupertinoFieldPadding(
                        CupertinoTextField(
                          controller: _motherTongueCtrl,
                          placeholder: 'Mother Tongue',
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: cupertinoDecoration(context),
                      child: cupertinoFieldPadding(
                        CupertinoTextField(
                          controller: _ethnicityCtrl,
                          placeholder: 'Ethnicity',
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ),
                    _chipSelector(
                      label: 'Profile For',
                      options: profileForOptions,
                      value: _profileFor,
                      onChanged: (v) => setState(() => _profileFor = v),
                    ),
                  ]),
                  _sectionCard('Contact', [
                    Container(
                      decoration: cupertinoDecoration(context),
                      child: cupertinoFieldPadding(
                        CupertinoTextField(
                          controller: _phoneCtrl,
                          placeholder: 'Phone Number',
                          keyboardType: TextInputType.phone,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  _sectionCard('Partner Preferences', [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: cupertinoDecoration(context),
                            child: cupertinoFieldPadding(
                              CupertinoTextField(
                                controller: _partnerAgeMinCtrl,
                                placeholder: 'Age Min',
                                keyboardType: TextInputType.number,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(color: Colors.transparent),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: cupertinoDecoration(context),
                            child: cupertinoFieldPadding(
                              CupertinoTextField(
                                controller: _partnerAgeMaxCtrl,
                                placeholder: 'Age Max',
                                keyboardType: TextInputType.number,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(color: Colors.transparent),
                                ),
                              ),
                            ),
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

  void _bootstrapFromProfile() {
    final authState = ref.read(authControllerProvider);
    final p = authState.profile;

    if (p == null) {
      // Profile not loaded yet, try to refresh it
      print('EditProfile: Profile is null, refreshing...');
      ref.read(authControllerProvider.notifier).refreshProfileOnly();
      return;
    }

    if (_hasBootstrapped) {
      print('EditProfile: Already bootstrapped, skipping...');
      return;
    }

    print('EditProfile: Bootstrapping profile data...');

    // Set all the form values from the profile
    _nameCtrl.text = p.fullName ?? '';
    _aboutCtrl.text = p.aboutMe ?? '';
    _cityCtrl.text = p.city ?? '';
    _countryCtrl.text = p.country ?? _countryCtrl.text;
    if (p.height != null && p.height! > 0) {
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

    // Handle date of birth
    if (p.dateOfBirth != null) {
      _dob = p.dateOfBirth;
    }

    // Handle partner preferences
    if (p.partnerPreferenceAgeMin != null) {
      _partnerAgeMinCtrl.text = p.partnerPreferenceAgeMin.toString();
    }
    if (p.partnerPreferenceAgeMax != null) {
      _partnerAgeMaxCtrl.text = p.partnerPreferenceAgeMax.toString();
    }
    if (p.partnerPreferenceCity != null && p.partnerPreferenceCity is List) {
      _partnerCities.addAll(List<String>.from(p.partnerPreferenceCity!));
    }

    print('EditProfile: Profile data loaded successfully');
    setState(() {
      _hasBootstrapped = true;
    });
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
    final first = DateTime(now.year - 80, now.month, now.day);
    final last = DateTime(now.year - 18, now.month, now.day);

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
                        onPressed: () => Navigator.pop(context, _dob),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime:
                        _dob ?? DateTime(now.year - 25, now.month, now.day),
                    minimumDate: first,
                    maximumDate: last,
                    onDateTimeChanged: (DateTime newDate) {
                      setState(() => _dob = newDate);
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
      setState(() => _dob = picked);
    }
  }

  void _showOptionPicker(
    BuildContext context,
    String title,
    List<String> options,
    String? currentValue,
    void Function(String?) onChanged,
  ) {
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
                      onChanged(options[selectedItem]);
                    },
                    children: options.map((option) {
                      return Center(child: Text(option));
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
            color: theme.shadowColor.withValues(alpha: 0.04),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
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
                  _showOptionPicker(context, label, options, value, onChanged),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value ?? 'Select',
                    style: CupertinoTheme.of(context).textTheme.textStyle
                        .copyWith(
                          color: value == null
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
    );
  }

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

  // (Old dropdown helper removed; replaced by chip selector UI.)

  String _dobLabel() => _dob == null
      ? 'Select date of birth'
      : _dob!.toIso8601String().split('T').first;
}

// Options for chip selectors
const List<String> genderOptions = [
  'male',
  'female',
  'non-binary',
  'prefer-not-to-say',
];

const List<String> preferredGenderOptions = ['male', 'female', 'any'];

const List<String> maritalStatusOptions = [
  'single',
  'divorced',
  'widowed',
  'separated',
];

const List<String> physicalStatusOptions = [
  'normal',
  'differently-abled',
  'athletic',
];

const List<String> dietOptions = [
  'vegetarian',
  'non-vegetarian',
  'vegan',
  'halal',
  'kosher',
];

const List<String> smokingOptions = [
  'never',
  'occasionally',
  'regularly',
  'socially',
];

const List<String> drinkingOptions = [
  'never',
  'occasionally',
  'socially',
  'regularly',
];

const List<String> profileForOptions = [
  'self',
  'sibling',
  'child',
  'friend',
  'relative',
];

const List<String> defaultInterestSuggestions = [
  'Music',
  'Movies',
  'Travel',
  'Sports',
  'Reading',
  'Cooking',
  'Photography',
  'Art',
  'Technology',
  'Fitness',
  'Dancing',
  'Gaming',
];
