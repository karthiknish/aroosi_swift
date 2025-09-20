import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aroosi_flutter/core/permissions.dart';

import 'package:aroosi_flutter/core/data/country_dial_codes.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/profiles/profile_image.dart';
import 'package:aroosi_flutter/features/profiles/profiles_repository.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';
import 'package:aroosi_flutter/utils/debug_logger.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  int _currentStepIndex = 0;
   final Map<String, dynamic> _data = <String, dynamic>{
     'country': 'UK',
     'profileFor': 'self',
     'interests': <String>[],
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
   final Set<String> _interests = {};

  DateTime? _dateOfBirth;

  late final ProfilesRepository _profilesRepository;
  final ImagePicker _picker = ImagePicker();

  List<ProfileImage> _images = const [];
  final List<_PendingUpload> _pendingUploads = <_PendingUpload>[];

  bool _loadingImages = false;
  bool _submitting = false;
  String? _error;

  String? _selectedDialCode; // stores currently selected dial code like +44
  bool?
  _selectedDialCodeInitialized; // guard to avoid re-splitting existing number repeatedly

  static const int _maxImages = 5;
  static const int _minimumAboutMeWords = 10;

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
     {'title': 'Lifestyle', 'subtitle': 'Your preferences'},
     {'title': 'About Me', 'subtitle': 'Describe yourself'},
     {'title': 'Photos', 'subtitle': 'Add your profile photos'},
     {'title': 'Review', 'subtitle': 'Confirm & create your profile'},
   ];

  static const List<String> _globalRequiredFields = <String>[
    'fullName',
    'dateOfBirth',
    'gender',
    'preferredGender',
    'city',
    'aboutMe',
    'occupation',
    'education',
    'height',
    'maritalStatus',
    'phoneNumber',
  ];

  static const Map<int, List<String>> _stepRequirements = <int, List<String>>{
    0: <String>[
      'fullName',
      'gender',
      'preferredGender',
      'dateOfBirth',
      'profileFor',
    ],
    1: <String>['country', 'city'],
    2: <String>['height', 'maritalStatus'],
    3: <String>['education', 'occupation'],
    4: <String>['motherTongue', 'religion', 'ethnicity'],
    5: <String>['diet', 'smoking', 'drinking', 'physicalStatus'],
    6: <String>['aboutMe', 'phoneNumber'],
    7: <String>['profileImageIds'],
  };

  @override
  void initState() {
    super.initState();
    _profilesRepository = ref.read(profilesRepositoryProvider);
    _loadExistingImages();
  }

  Future<void> _loadExistingImages() async {
    final userId = _currentUserId();
    if (userId == null) return;
    setState(() => _loadingImages = true);
    try {
      final images = await _profilesRepository.fetchProfileImages(
        userId: userId,
      );
      if (!mounted) return;
      setState(() {
        _images = images;
        _loadingImages = false;
      });
      _syncImageIds();
    } catch (_) {
      if (mounted) {
        setState(() => _loadingImages = false);
      }
    }
  }

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

  String? _currentUserId() {
    final authState = ref.read(authControllerProvider);
    final profileId = authState.profile?.id;
    if (profileId != null && profileId.isNotEmpty) return profileId;
    final firebaseUser = fb.FirebaseAuth.instance.currentUser;
    return firebaseUser?.uid;
  }

  void _syncImageIds() {
    if (_images.isEmpty) {
      _data.remove('profileImageIds');
      _data.remove('localImageIds');
      return;
    }
    final ids = _images
        .map((img) => img.identifier)
        .where((id) => id.isNotEmpty)
        .toList();
    _data['profileImageIds'] = ids;
    _data['localImageIds'] = ids;
  }

  void _onBack() {
    if (_submitting) return;
    if (_currentStepIndex == 0) {
      if (mounted) context.go('/onboarding');
      return;
    }
    setState(() {
      _currentStepIndex -= 1;
      _error = null;
    });
  }

  Future<void> _onNext() async {
    if (_submitting) return;
    if (!await _validateCurrentStep()) return;
    if (_currentStepIndex < _steps.length - 1) {
      setState(() {
        _currentStepIndex += 1;
        _error = null;
      });
    }
  }

  Future<void> _pickImages() async {
    final ok = await AppPermissions.ensurePhotoAccess();
    if (!ok) return;
    if (_images.length + _pendingUploads.length >= _maxImages) {
      ToastService.instance.info('You can upload up to $_maxImages photos.');
      return;
    }
    final remaining = _maxImages - (_images.length + _pendingUploads.length);
    try {
      final files = await _picker.pickMultiImage(imageQuality: 85);
      if (files.isEmpty) return;
      final toUpload = files.take(remaining);
      for (final file in toUpload) {
        await _uploadImage(file);
      }
    } on PlatformException catch (e) {
      ToastService.instance.error(
        'Image picker unavailable: ${e.message ?? 'Permission denied'}',
      );
    } catch (e) {
      ToastService.instance.error('Failed to pick images: $e');
    }
  }

  Future<void> _uploadImage(XFile file) async {
    final userId = _currentUserId();
    if (userId == null) {
      ToastService.instance.error('You need to be signed in to upload images.');
      return;
    }
    final pending = _PendingUpload(id: file.path, path: file.path);
    setState(() => _pendingUploads.add(pending));
    try {
      final image = await _profilesRepository.uploadProfileImage(
        file: file,
        userId: userId,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => pending.progress = progress);
        },
      );
      if (!mounted) return;
      setState(() {
        _pendingUploads.remove(pending);
        _images = <ProfileImage>[..._images, image];
      });
      _syncImageIds();
    } catch (e) {
      if (!mounted) return;
      setState(() => _pendingUploads.remove(pending));
      ToastService.instance.error('Failed to upload image: $e');
    }
  }

  Future<void> _deleteImage(ProfileImage image) async {
    final userId = _currentUserId();
    if (userId == null) {
      ToastService.instance.error('Unable to delete image without user id.');
      return;
    }
    try {
      await _profilesRepository.deleteProfileImage(
        userId: userId,
        imageId: image.identifier,
      );
      if (!mounted) return;
      setState(() {
        _images = _images
            .where((img) => img.identifier != image.identifier)
            .toList();
      });
      _syncImageIds();
    } catch (e) {
      ToastService.instance.error('Failed to delete image: $e');
    }
  }

  Future<void> _makePrimary(ProfileImage image) async {
    if (_images.isEmpty) return;
    final userId = _currentUserId();
    if (userId == null) {
      ToastService.instance.error('Unable to reorder images without user id.');
      return;
    }
    final reordered = <ProfileImage>[
      image,
      ..._images.where((img) => img.identifier != image.identifier),
    ];
    setState(() {
      _images = reordered;
    });
    _syncImageIds();
    try {
      await _profilesRepository.reorderProfileImages(
        userId: userId,
        imageIds: reordered.map((img) => img.identifier).toList(),
      );
    } catch (e) {
      ToastService.instance.warning('Unable to update photo order: $e');
    }
  }

  Future<bool> _validateCurrentStep() async {
    final form = _formKey.currentState;
    if (form != null && !form.validate()) {
      return false;
    }
    form?.save();

    if (_currentStepIndex == 0 && _dateOfBirth == null) {
      ToastService.instance.error('Please select your date of birth.');
      return false;
    }
    if (_currentStepIndex == 5) {
      final about = _aboutMeCtrl.text.trim();
      if (!_hasAtLeastWords(about, _minimumAboutMeWords)) {
        ToastService.instance.error(
          'Tell us a little more about yourself (at least $_minimumAboutMeWords words).',
        );
        return false;
      }
    }
    if (_currentStepIndex == 7 && _images.isEmpty) {
      ToastService.instance.error('Add at least one photo to continue.');
      return false;
    }

    final requiredKeys = _stepRequirements[_currentStepIndex];
    if (requiredKeys != null) {
      for (final key in requiredKeys) {
        if (!_hasValueForKey(key)) {
          ToastService.instance.error(
            'Please complete the required details before continuing.',
          );
          return false;
        }
      }
    }
    return true;
  }

  bool _hasValueForKey(String key) {
    final value = _data[key];
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    return true;
  }

  String _formatDob(DateTime? dob) {
    if (dob == null) return '';
    return '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
  }

  String? _normalizePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final digits = cleaned.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 10 && digits.length <= 15) {
      return '+$digits';
    }
    return phone.trim();
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  bool _isValidPhone(String value) {
    final normalized = _normalizePhoneNumber(value);
    if (normalized == null) return false;
    return RegExp(r'^\+[1-9][\d]{9,14}$').hasMatch(normalized);
  }

  bool _hasAtLeastWords(String text, int words) {
    final tokens = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return tokens.length >= words;
  }

  InputDecoration _decoration(BuildContext buildContext, String label, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final step = _steps[_currentStepIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Inline back button row
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () {
                if (_submitting) return;
                if (_currentStepIndex == 0) {
                  logNav('profile_setup: back from step0 -> /onboarding');
                  if (mounted) context.go('/onboarding');
                } else {
                  logNav(
                    'profile_setup: back step $_currentStepIndex -> ${_currentStepIndex - 1}',
                  );
                  _onBack();
                }
              },
            ),
            const Spacer(),
            // Optionally show skip or close in future
          ],
        ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: LinearProgressIndicator(
            value: (_currentStepIndex + 1) / _steps.length,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainer,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_currentStepIndex + 1} of ${_steps.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${(_calculateCompletionPercentage() * 100).round()}% complete)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int? _ageFromDob(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    final hadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) age -= 1;
    return age;
  }

  double _calculateCompletionPercentage() {
    // Base completion from current step
    final stepProgress = (_currentStepIndex + 1) / _steps.length;

    // Additional completion based on filled required fields
    final requiredFields = _globalRequiredFields;
    final filledFields = requiredFields.where((field) {
      final value = _data[field];
      return value != null &&
             value != '' &&
             (value is! List || value.isNotEmpty);
    }).length;

    final fieldProgress = filledFields / requiredFields.length;

    // Weighted average: 60% from steps, 40% from field completion
    return (stepProgress * 0.6) + (fieldProgress * 0.4);
  }

  Widget _stepBasicInfo(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium;
    final age = _dateOfBirth == null ? null : _ageFromDob(_dateOfBirth!);
    return Column(
      children: [
        TextFormField(
          controller: _fullNameCtrl,
          decoration: _decoration(context, 'Full name'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name';
            }
            if (value.trim().length < 2) {
              return 'Full name must be at least 2 characters';
            }
            if (value.trim().length > 50) {
              return 'Full name must be less than 50 characters';
            }
            return null;
          },
          onChanged: (value) => _data['fullName'] = value.trim(),
          onSaved: (value) => _data['fullName'] = value?.trim(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: _decoration(context, 'Gender'),
                initialValue: (_data['gender'] as String?),
                items: _genderOptions
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(_capitalize(g), style: textStyle),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _data['gender'] = value),
                validator: (value) => value == null || value.isEmpty
                    ? 'Gender is required'
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: _decoration(context, 'Looking for'),
                initialValue: (_data['preferredGender'] as String?),
                items: _preferredGenderOptions
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(_capitalize(g), style: textStyle),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _data['preferredGender'] = value),
                validator: (value) => value == null || value.isEmpty
                    ? 'This field is required'
                    : null,
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
                decoration: _decoration(context,
                  'Date of birth',
                  hint: 'Select date',
                ).copyWith(suffixIcon: const Icon(Icons.calendar_today)),
                controller: TextEditingController(
                  text: _formatDob(_dateOfBirth),
                ),
                validator: (_) {
                  if (_dateOfBirth == null) return 'Date of birth is required';
                  final parsedAge = age;
                  if (parsedAge == null || parsedAge < 18 || parsedAge > 120) {
                    return 'You must be between 18 and 120 years old';
                  }
                  return null;
                },
                onTap: () async {
                  final now = DateTime.now();
                  final first = DateTime(now.year - 120, now.month, now.day);
                  final last = DateTime(now.year - 18, now.month, now.day);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dateOfBirth ?? last,
                    firstDate: first,
                    lastDate: last,
                  );
                  if (picked != null) {
                    setState(() {
                      _dateOfBirth = picked;
                      _data['dateOfBirth'] = picked.toIso8601String();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: _decoration(context,'Religion'),
                initialValue: (_data['religion'] as String?) ?? '',
                items: _religionOptions
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value.isEmpty
                              ? 'Prefer not to say'
                              : _capitalize(value),
                          style: textStyle,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _data['religion'] = value == null || value.isEmpty
                      ? null
                      : value;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: _decoration(context,'Mother tongue'),
                initialValue: (_data['motherTongue'] as String?) ?? '',
                items: _motherTongueOptions
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value.isEmpty
                              ? 'Prefer not to say'
                              : _capitalize(value),
                          style: textStyle,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _data['motherTongue'] = value == null || value.isEmpty
                      ? null
                      : value;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _ethnicityCtrl,
                decoration: _decoration(context,
                  'Ethnicity (optional)',
                  hint: 'e.g., British Afghan',
                ),
                onSaved: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    _data.remove('ethnicity');
                  } else {
                    _data['ethnicity'] = trimmed;
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: _decoration(context,'Profile for'),
          initialValue: (_data['profileFor'] as String?) ?? 'self',
          items: _profileForOptions
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_capitalize(value), style: textStyle),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _data['profileFor'] = value),
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
          isExpanded: true,
          decoration: _decoration(context,'Country'),
          initialValue: (_data['country'] as String?) ?? 'UK',
          items: _countries
              .map(
                (country) => DropdownMenuItem(
                  value: country,
                  child: Text(country, style: textStyle),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _data['country'] = value),
          validator: (value) =>
              value == null || value.isEmpty ? 'Country is required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cityCtrl,
          decoration: _decoration(context,'City'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your city';
            }
            if (value.trim().length < 2) {
              return 'City must be at least 2 characters';
            }
            if (value.trim().length > 50) {
              return 'City must be less than 50 characters';
            }
            return null;
          },
          onChanged: (value) => _data['city'] = value.trim(),
          onSaved: (value) => _data['city'] = value?.trim(),
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
          decoration: _decoration(context,'Height (cm)', hint: '100 - 250'),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your height';
            }
            final num? parsed = num.tryParse(value.trim());
            if (parsed == null || parsed < 100 || parsed > 250) {
              return 'Height must be between 100-250 cm';
            }
            return null;
          },
          onChanged: (value) => _data['height'] = value.trim(),
          onSaved: (value) => _data['height'] = value?.trim(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: _decoration(context,'Marital status'),
          initialValue: (_data['maritalStatus'] as String?),
          items: _maritalStatusOptions
              .map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(_capitalize(status), style: textStyle),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _data['maritalStatus'] = value),
          validator: (value) => value == null || value.isEmpty
              ? 'Marital status is required'
              : null,
        ),
      ],
    );
  }

  Widget _stepProfessional(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _educationCtrl,
          decoration: _decoration(context,'Education'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your education level';
            }
            if (value.trim().length < 2) {
              return 'Education must be at least 2 characters';
            }
            return null;
          },
          onChanged: (value) => _data['education'] = value.trim(),
          onSaved: (value) => _data['education'] = value?.trim(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _occupationCtrl,
          decoration: _decoration(context,'Occupation'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your occupation';
            }
            if (value.trim().length < 2) {
              return 'Occupation must be at least 2 characters';
            }
            return null;
          },
          onChanged: (value) => _data['occupation'] = value.trim(),
          onSaved: (value) => _data['occupation'] = value?.trim(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _annualIncomeCtrl,
          decoration: _decoration(context,
            'Annual income (£) (optional)',
            hint: 'e.g., 50000',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final num? parsed = num.tryParse(value.trim());
            if (parsed == null || parsed < 0 || parsed > 1000000) {
              return 'Enter a valid amount';
            }
            return null;
          },
          onSaved: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              _data.remove('annualIncome');
            } else {
              _data['annualIncome'] = trimmed;
            }
          },
        ),
      ],
    );
  }

  Widget _stepCultural(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: _decoration(context,'Mother tongue'),
                initialValue: (_data['motherTongue'] as String?) ?? '',
                items: _motherTongueOptions
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value.isEmpty ? 'Prefer not to say' : _capitalize(value),
                          style: textStyle,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _data['motherTongue'] = value == null || value.isEmpty
                      ? null
                      : value;
                }),
                validator: (value) => value == null || value.isEmpty
                    ? 'Mother tongue is required'
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: _decoration(context,'Religion'),
                initialValue: (_data['religion'] as String?) ?? '',
                items: _religionOptions
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value.isEmpty ? 'Prefer not to say' : _capitalize(value),
                          style: textStyle,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _data['religion'] = value == null || value.isEmpty
                      ? null
                      : value;
                }),
                validator: (value) => value == null || value.isEmpty
                    ? 'Religion is required'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _ethnicityCtrl,
          decoration: _decoration(context,
            'Ethnicity (optional)',
            hint: 'e.g., British Afghan',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            if (value.trim().length < 2) {
              return 'Ethnicity must be at least 2 characters';
            }
            return null;
          },
          onSaved: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              _data.remove('ethnicity');
            } else {
              _data['ethnicity'] = trimmed;
            }
          },
        ),
      ],
    );
  }

  Widget _stepAboutMe(BuildContext context) {
    // Country dial code selection state (persist across rebuilds)
    _selectedDialCode ??= '+1'; // default fallback

    // If editing an existing full phone number, attempt to split into dial code + local part once.
    if (_phoneCtrl.text.isNotEmpty && _selectedDialCodeInitialized != true) {
      final existing = _phoneCtrl.text.trim();
      // Match leading + and digits
      final match = RegExp(r'^\+(\d{1,4})').firstMatch(existing);
      if (match != null) {
        final group = match.group(1);
        if (group == null) {
          // Handle the case where the group is null
          _selectedDialCode = '+1'; // default fallback
          _selectedDialCodeInitialized = true;
        } else {
          final code = '+$group';
          final found = kCountryDialCodes.firstWhere(
            (c) => c.dialCode == code,
            orElse: () =>
                kCountryDialCodes.firstWhere((c) => c.dialCode == '+1'),
          );
          _selectedDialCode = found.dialCode;
          final national = existing.substring(code.length).trim();
          if (national.isNotEmpty) {
            // Avoid overwriting if user already modified
            _phoneCtrl.text = national;
          }
        }
        _selectedDialCodeInitialized = true;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _aboutMeCtrl,
          decoration: _decoration(context,
            'About me',
            hint: 'Share your story (min $_minimumAboutMeWords words)',
          ),
          maxLines: 6,
          minLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Tell us about yourself';
            }
            if (!_hasAtLeastWords(value, _minimumAboutMeWords)) {
              return 'Write at least $_minimumAboutMeWords words';
            }
            return null;
          },
          onChanged: (value) => _data['aboutMe'] = value.trim(),
          onSaved: (value) => _data['aboutMe'] = value?.trim(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: _decoration(context,'Code'),
                value: _selectedDialCode,
                items: kCountryDialCodes
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c.dialCode,
                        child: Text(
                          '${c.flag}  ${c.dialCode}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedDialCode = val;
                    _updateComposedPhone();
                  });
                },
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 12,
              child: TextFormField(
                controller: _phoneCtrl,
                decoration: _decoration(context,
                  'Phone number',
                  hint: 'National number',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final raw = value?.trim() ?? '';
                  if (raw.isEmpty) return 'Phone number is required';
                  final full = (_selectedDialCode ?? '') + raw;
                  if (!_isValidPhone(full)) {
                    return 'Enter valid number';
                  }
                  return null;
                },
                onChanged: (value) {
                  _updateComposedPhone();
                },
                onSaved: (value) {
                  _updateComposedPhone();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepLifestyle(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: _decoration(context,'Diet (optional)'),
                initialValue: (_data['diet'] as String?),
                items: _dietOptions
                    .map(
                      (diet) => DropdownMenuItem(
                        value: diet,
                        child: Text(_capitalize(diet), style: textStyle),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  if (value == null || value.isEmpty) {
                    _data.remove('diet');
                  } else {
                    _data['diet'] = value;
                  }
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: _decoration(context,'Physical status (optional)'),
                initialValue: (_data['physicalStatus'] as String?),
                items: _physicalStatusOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(_capitalize(option), style: textStyle),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  if (value == null || value.isEmpty) {
                    _data.remove('physicalStatus');
                  } else {
                    _data['physicalStatus'] = value;
                  }
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: _decoration(context,'Smoking preference (optional)'),
          initialValue: (_data['smoking'] as String?),
          items: _smokingDrinkingOptions
              .map(
                (option) => DropdownMenuItem(
                  value: option,
                  child: Text(_capitalize(option), style: textStyle),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() {
            if (value == null || value.isEmpty) {
              _data.remove('smoking');
            } else {
              _data['smoking'] = value;
            }
          }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: _decoration(context,'Drinking preference (optional)'),
          initialValue: (_data['drinking'] as String?),
          items: _smokingDrinkingOptions
              .map(
                (option) => DropdownMenuItem(
                  value: option,
                  child: Text(_capitalize(option), style: textStyle),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() {
            if (value == null || value.isEmpty) {
              _data.remove('drinking');
            } else {
              _data['drinking'] = value;
            }
          }),
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
                decoration: _decoration(context,'Min age', hint: '18'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final int? minAge = int.tryParse(value.trim());
                  if (minAge == null || minAge < 18 || minAge > 120) {
                    return '18-120';
                  }
                  final int? maxAge = int.tryParse(
                    _partnerMaxAgeCtrl.text.trim(),
                  );
                  if (maxAge != null && minAge > maxAge) {
                    return '<= Max age';
                  }
                  return null;
                },
                onSaved: (value) {
                  final trimmed = value?.trim() ?? '';
                  _data['partnerPreferenceAgeMin'] = trimmed.isEmpty
                      ? null
                      : int.tryParse(trimmed);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _partnerMaxAgeCtrl,
                decoration: _decoration(context,'Max age', hint: '120'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final int? maxAge = int.tryParse(value.trim());
                  if (maxAge == null || maxAge < 18 || maxAge > 120) {
                    return '18-120';
                  }
                  final int? minAge = int.tryParse(
                    _partnerMinAgeCtrl.text.trim(),
                  );
                  if (minAge != null && minAge > maxAge) {
                    return '>= Min age';
                  }
                  return null;
                },
                onSaved: (value) {
                  final trimmed = value?.trim() ?? '';
                  _data['partnerPreferenceAgeMax'] = trimmed.isEmpty
                      ? null
                      : int.tryParse(trimmed);
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add photos to showcase your personality. Your first photo will be your main picture.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Add photos'),
                    onPressed:
                        _images.length + _pendingUploads.length >= _maxImages
                        ? null
                        : _pickImages,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: Text(
                    'Add photos to showcase your personality. Your first photo will be your main picture.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Add photos'),
                  onPressed:
                      _images.length + _pendingUploads.length >= _maxImages
                      ? null
                      : _pickImages,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        if (_loadingImages && _images.isEmpty)
          const Center(child: CircularProgressIndicator()),
        if (_images.isEmpty && _pendingUploads.isEmpty && !_loadingImages)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Add at least one clear photo to build trust.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._pendingUploads.map(
              (upload) => _buildPendingThumbnail(context, upload),
            ),
            ..._images.map((image) => _buildImageThumbnail(context, image)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${math.min(_images.length, _maxImages)}/$_maxImages photos uploaded',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPendingThumbnail(BuildContext context, _PendingUpload upload) {
    final placeholder = Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: kIsWeb
            ? Container(
                color: Theme.of(context).colorScheme.surface,
                child: const Icon(Icons.photo, size: 32),
              )
            : Image.file(File(upload.path), fit: BoxFit.cover),
      ),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        placeholder,
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '${(upload.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(BuildContext context, ProfileImage image) {
    final theme = Theme.of(context);
    final isPrimary = _images.isNotEmpty && image == _images.first;
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surfaceContainer,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image.url != null && image.url!.isNotEmpty
                ? Image.network(image.url!, fit: BoxFit.cover)
                : Container(
                    color: theme.colorScheme.surface,
                    child: const Icon(Icons.photo, size: 32),
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => _deleteImage(image),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              backgroundColor: isPrimary
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              foregroundColor: isPrimary
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
            onPressed: isPrimary ? null : () => _makePrimary(image),
            child: Text(
              isPrimary ? 'Primary' : 'Make primary',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepReview(BuildContext context) {
    final theme = Theme.of(context);
    final reviewItems = <MapEntry<String, String>>[
      MapEntry('Full name', _fullNameCtrl.text.trim()),
      MapEntry('City', _cityCtrl.text.trim()),
      MapEntry('Country', _data['country']?.toString() ?? ''),
      MapEntry(
        'Marital status',
        _capitalize(_data['maritalStatus']?.toString() ?? ''),
      ),
      MapEntry('Occupation', _occupationCtrl.text.trim()),
      MapEntry('Education', _educationCtrl.text.trim()),
      MapEntry('About me', _aboutMeCtrl.text.trim()),
      MapEntry('Phone', _phoneCtrl.text.trim()),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Review your details before submitting. You can edit them later from your profile.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...reviewItems.map(
          (entry) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(entry.value.isEmpty ? 'Not provided' : entry.value),
              ],
            ),
          ),
        ),
        if (_images.isNotEmpty) ...[
          Text('Photos', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _images
                .map(
                  (image) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: image.url != null && image.url!.isNotEmpty
                          ? Image.network(image.url!, fit: BoxFit.cover)
                          : Container(
                              color: theme.colorScheme.surfaceContainer,
                              child: const Icon(Icons.photo),
                            ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final valid = await _validateCurrentStep();
    if (!valid) return;

    // Check for missing required fields before submission
    final missingFields = _getMissingRequiredFields();
    if (missingFields.isNotEmpty) {
      ToastService.instance.error(
        'Cannot create profile. Missing required fields: ${missingFields.take(3).join(', ')}${missingFields.length > 3 ? ' and more' : ''}. Please go back and complete all sections.',
      );
      return;
    }

    final payload = _buildPayload();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _profilesRepository.createProfile(payload);
      await ref.read(authControllerProvider.notifier).refresh();
      if (!mounted) return;
      ToastService.instance.success('Profile created successfully.');
      context.go('/onboarding/complete');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      ToastService.instance.error('Failed to create profile: $e');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  List<String> _getMissingRequiredFields() {
    final payload = _buildPayload();
    return _globalRequiredFields.where((field) {
      final value = payload[field];
      return value == null ||
             (value is String && value.trim().isEmpty) ||
             (value is List && value.isEmpty);
    }).toList();
  }

  Map<String, dynamic> _buildPayload() {
    final Map<String, dynamic> payload = <String, dynamic>{
      'fullName': _fullNameCtrl.text.trim(),
      'dateOfBirth':
          (_dateOfBirth ??
                  DateTime.tryParse(_data['dateOfBirth']?.toString() ?? ''))
              ?.toIso8601String(),
      'gender': _data['gender'],
      'preferredGender': _data['preferredGender'],
      'city': _cityCtrl.text.trim(),
      'country': _data['country'],
      'height': _heightCtrl.text.trim(),
      'maritalStatus': _data['maritalStatus'],
      'education': _educationCtrl.text.trim(),
      'occupation': _occupationCtrl.text.trim(),
      'annualIncome': _annualIncomeCtrl.text.trim().isEmpty
          ? null
          : _annualIncomeCtrl.text.trim(),
      'aboutMe': _aboutMeCtrl.text.trim(),
      'phoneNumber': _normalizePhoneNumber(_phoneCtrl.text.trim()),
      'religion': _data['religion'],
      'motherTongue': _data['motherTongue'],
      'ethnicity': _ethnicityCtrl.text.trim().isEmpty
          ? null
          : _ethnicityCtrl.text.trim(),
      'diet': _data['diet'],
      'smoking': _data['smoking'],
      'drinking': _data['drinking'],
      'physicalStatus': _data['physicalStatus'],
      'partnerPreferenceAgeMin': (_partnerMinAgeCtrl.text.trim().isEmpty)
          ? null
          : int.tryParse(_partnerMinAgeCtrl.text.trim()),
      'partnerPreferenceAgeMax': (_partnerMaxAgeCtrl.text.trim().isEmpty)
          ? null
          : int.tryParse(_partnerMaxAgeCtrl.text.trim()),
      'profileFor': _data['profileFor'],
      'profileImageIds': _data['profileImageIds'],
      'localImageIds': _data['localImageIds'],
    };

    payload.removeWhere(
      (key, value) =>
          value == null || (value is String && value.trim().isEmpty),
    );
    return payload;
  }

  void _updateComposedPhone() {
    final local = _phoneCtrl.text.trim();
    final code = _selectedDialCode ?? '';
    // Phone storage contract:
    // Always attempt to store full international number in E.164-like form: +<countrycode><national>
    // If user pasted a full number already (with +), trust and store as-is.
    // Otherwise compose using selected dial code + national significant number without spaces.
    if (local.isEmpty || code.isEmpty) {
      _data.remove('phoneNumber');
      return;
    }
    if (local.startsWith(code)) {
      _data['phoneNumber'] =
          local; // Already composed (user maybe switched code after paste) – we keep as is.
    } else if (local.startsWith('+')) {
      _data['phoneNumber'] =
          local; // Full number pasted with a different code; respect user input.
    } else {
      _data['phoneNumber'] = '$code$local';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
        stepContent = _stepLifestyle(context);
        break;
      case 6:
        stepContent = _stepAboutMe(context);
        break;
      case 7:
        stepContent = _stepPhotos(context);
        break;
      default:
        stepContent = _stepReview(context);
        break;
    }

    return WillPopScope(
      onWillPop: () async {
        if (_submitting) return false;
        if (_currentStepIndex == 0) {
          if (mounted) context.go('/onboarding');
          return false;
        }
        _onBack();
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: FadeThrough(
            delay: AppMotionDurations.fast,
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildHeader(context),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _error ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FadeSlideIn(
                          duration: AppMotionDurations.medium,
                          beginOffset: const Offset(0, 0.05),
                          child: stepContent,
                        ),
                        const SizedBox(height: 32),
                        _buildControls(context),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final isLastStep = _currentStepIndex == _steps.length - 1;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _currentStepIndex == 0 || _submitting ? null : _onBack,
            child: const Text('Back'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _submitting
                ? null
                : isLastStep
                ? _submit
                : _onNext,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isLastStep ? 'Create Profile' : 'Next'),
          ),
        ),
      ],
    );
  }
}

class _PendingUpload {
  _PendingUpload({required this.id, required this.path}) : progress = 0;

  final String id;
  final String path;
  double progress;
}
