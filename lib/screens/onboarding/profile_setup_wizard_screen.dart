import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/profiles/profiles_repository.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';
import 'package:aroosi_flutter/l10n/app_localizations.dart';

import 'steps/steps.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _currentStepIndex = 0;
  final Map<String, dynamic> _data = <String, dynamic>{
    StepConstants.country: StepConstants.defaultCountry,
    StepConstants.profileFor: StepConstants.defaultProfileFor,
    StepConstants.physicalStatus: StepConstants.defaultPhysicalStatus,
    StepConstants.partnerPreferenceCity: <String>[],
  };

  late final ProfilesRepository _profilesRepository;
  bool _submitting = false;
  String? _error;

  // Step form keys
  final GlobalKey<FormState> _basicInfoFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _locationFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _physicalDetailsFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _professionalFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _culturalFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _aboutMeFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _lifestyleFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _photosFormKey = GlobalKey<FormState>();

  static const List<String> _globalRequiredFields = <String>[
    StepConstants.fullName,
    StepConstants.dateOfBirth,
    StepConstants.gender,
    StepConstants.preferredGender,
    StepConstants.city,
    StepConstants.aboutMe,
    StepConstants.occupation,
    StepConstants.education,
    StepConstants.height,
    StepConstants.maritalStatus,
    StepConstants.phoneNumber,
  ];

  @override
  void initState() {
    super.initState();
    _profilesRepository = ref.read(profilesRepositoryProvider);
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? _currentUserId() {
    final authState = ref.read(authControllerProvider);
    final profileId = authState.profile?.id;
    if (profileId != null && profileId.isNotEmpty) return profileId;
    return null;
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

    // Validate current step
    if (!await _validateCurrentStep()) {
      return;
    }

    if (_currentStepIndex < StepInfo.allSteps.length - 1) {
      setState(() {
        _currentStepIndex += 1;
        _error = null;
      });
    }
  }

  GlobalKey<FormState> _getStepFormKey() {
    switch (_currentStepIndex) {
      case 0:
        return _basicInfoFormKey;
      case 1:
        return _locationFormKey;
      case 2:
        return _physicalDetailsFormKey;
      case 3:
        return _professionalFormKey;
      case 4:
        return _culturalFormKey;
      case 5:
        return _aboutMeFormKey;
      case 6:
        return _lifestyleFormKey;
      case 7:
        return _photosFormKey;
      default:
        return _basicInfoFormKey;
    }
  }

  Future<bool> _validateCurrentStep() async {
    final formKey = _getStepFormKey();
    final form = formKey.currentState;

    if (form != null && !form.validate()) {
      debugPrint('Form validation failed for step $_currentStepIndex');
      return false;
    }

    form?.save();
    debugPrint('Validating step $_currentStepIndex');

    // For now, just return true - individual steps handle their own validation
    return true;
  }

  bool _hasValueForKey(String key) {
    final value = _data[key];
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    return true;
  }

  Future<void> _submit() async {
    if (_submitting) return;

    // Validate all required fields
    final requiredFields = _globalRequiredFields;
    for (final field in requiredFields) {
      if (!_hasValueForKey(field)) {
        ToastService.instance.error(
          'Cannot create profile. Missing required fields: ${requiredFields.take(3).join(', ')}${requiredFields.length > 3 ? ' and more' : ''}. Please complete all sections.',
        );
        return;
      }
    }

    final payload = _buildPayload();
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final result = await _profilesRepository.createProfile(payload);

      // Handle API response format
      if (result == null) {
        throw Exception('Profile creation failed: No response from server');
      }

      if (result['success'] == false) {
        final errorMessage =
            result['error'] ?? result['message'] ?? 'Failed to create profile';
        throw Exception(errorMessage);
      }

      await ref.read(authControllerProvider.notifier).refresh();
      if (!mounted) return;

      final successMessage =
          result['message'] ?? 'Profile created successfully.';
      ToastService.instance.success(successMessage);
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

  Map<String, dynamic> _buildPayload() {
    // Parse partner cities
    List<String> partnerCities = <String>[];
    final cities = _data[StepConstants.partnerPreferenceCity] as List<String>?;
    if (cities != null && cities.isNotEmpty) {
      partnerCities = cities;
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      StepConstants.fullName: _data[StepConstants.fullName],
      StepConstants.dateOfBirth: _data[StepConstants.dateOfBirth],
      StepConstants.gender: _data[StepConstants.gender],
      StepConstants.preferredGender: _data[StepConstants.preferredGender],
      StepConstants.city: _data[StepConstants.city],
      StepConstants.country: _data[StepConstants.country],
      StepConstants.height: _data[StepConstants.height],
      StepConstants.maritalStatus: _data[StepConstants.maritalStatus],
      StepConstants.physicalStatus: _data[StepConstants.physicalStatus],
      StepConstants.education: _data[StepConstants.education],
      StepConstants.occupation: _data[StepConstants.occupation],
      StepConstants.annualIncome: _data[StepConstants.annualIncome],
      StepConstants.aboutMe: _data[StepConstants.aboutMe],
      StepConstants.phoneNumber: _data[StepConstants.phoneNumber],
      StepConstants.religion: _data[StepConstants.religion],
      StepConstants.motherTongue: _data[StepConstants.motherTongue],
      StepConstants.ethnicity: _data[StepConstants.ethnicity],
      StepConstants.diet: _data[StepConstants.diet],
      StepConstants.smoking: _data[StepConstants.smoking],
      StepConstants.drinking: _data[StepConstants.drinking],
      StepConstants.partnerPreferenceAgeMin:
          _data[StepConstants.partnerPreferenceAgeMin],
      StepConstants.partnerPreferenceAgeMax:
          _data[StepConstants.partnerPreferenceAgeMax],
      StepConstants.partnerPreferenceCity: partnerCities,
      StepConstants.profileFor: _data[StepConstants.profileFor],
      StepConstants.profileImageIds: _data[StepConstants.profileImageIds],
    };

    payload.removeWhere(
      (key, value) =>
          value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty),
    );
    return payload;
  }

  void _updateField(String key, dynamic value) {
    setState(() {
      _data[key] = value;
    });
  }

  double _calculateCompletionPercentage() {
    // Base completion from current step
    final stepProgress = (_currentStepIndex + 1) / StepInfo.allSteps.length;

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

  IconData _getStepIcon(int stepIndex) {
    return StepInfo.getStep(stepIndex).icon;
  }

  String _getStepTitle(int stepIndex) {
    return StepInfo.getStep(stepIndex).title;
  }

  Widget _buildStepContent() {
    switch (_currentStepIndex) {
      case 0:
        return StepBasicInfo(
          initialData: _data,
          onDataUpdate: _updateField,
          formKey: _basicInfoFormKey,
        );
      case 1:
        return StepLocation(
          initialData: _data,
          onDataUpdate: _updateField,
          formKey: _locationFormKey,
        );
      case 2:
        return StepPhysicalDetails(
          initialData: _data,
          onDataUpdate: _updateField,
          formKey: _physicalDetailsFormKey,
        );
      case 3:
        return StepProfessional(
          initialData: _data,
          onDataUpdate: _updateField,
          formKey: _professionalFormKey,
        );
      case 4:
        return StepCultural(
          initialData: _data,
          onDataUpdate: _updateField,
          formKey: _culturalFormKey,
        );
      case 5:
        return StepAboutMe(
          initialData: _data,
          onDataUpdate: _updateField,
          formKey: _aboutMeFormKey,
        );
      case 6:
        return StepLifestyle(
          initialData: _data,
          onDataUpdate: _updateField,
          formKey: _lifestyleFormKey,
        );
      case 7:
        return StepPhotos(
          initialData: _data,
          onDataUpdate: _updateField,
          formKey: _photosFormKey,
        );
      default:
        return Container();
    }
  }

  Widget _buildHeader(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      constraints: const BoxConstraints(maxWidth: 800),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Modern Navigation Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withValues(alpha: 0.08),
                  theme.primaryColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    if (_submitting) return;
                    if (_currentStepIndex == 0) {
                      if (mounted) context.go('/onboarding');
                    } else {
                      _onBack();
                    }
                  },
                  child: Icon(CupertinoIcons.back, color: theme.primaryColor),
                ),
                const Spacer(),
                // Step Indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.person,
                        size: 16,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_currentStepIndex + 1}/${StepInfo.allSteps.length}',
                        style: theme.textTheme.textStyle.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Modern Title
          Text(
            AppLocalizations.of(context)!.profileCreateProfile,
            style: theme.textTheme.navTitleTextStyle.copyWith(
              fontWeight: FontWeight.w800,
              color: CupertinoColors.label,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Step Title with Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getStepIcon(_currentStepIndex),
                size: 24,
                color: theme.primaryColor.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStepTitle(_currentStepIndex),
                  style: theme.textTheme.textStyle.copyWith(
                    color: CupertinoColors.secondaryLabel,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Modern Progress Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.scaffoldBackgroundColor,
                  theme.barBackgroundColor.withValues(alpha: 0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: CupertinoColors.separator.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Progress Bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.barBackgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentStepIndex + 1) / StepInfo.allSteps.length,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.primaryColor,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Step Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(StepInfo.allSteps.length, (index) {
                    final isCompleted = index < _currentStepIndex;
                    final isCurrent = index == _currentStepIndex;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isCurrent ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? theme.primaryColor
                            : isCurrent
                            ? theme.primaryColor.withValues(alpha: 0.8)
                            : CupertinoColors.separator.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                // Progress Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile Setup',
                      style: theme.textTheme.textStyle.copyWith(
                        color: CupertinoColors.secondaryLabel,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _calculateCompletionPercentage() == 1.0
                            ? theme.primaryColor.withValues(alpha: 0.1)
                            : theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(_calculateCompletionPercentage() * 100).round()}% Complete',
                        style: theme.textTheme.textStyle.copyWith(
                          color: _calculateCompletionPercentage() == 1.0
                              ? theme.primaryColor
                              : theme.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final isLastStep = _currentStepIndex == StepInfo.allSteps.length - 1;
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            onPressed: _currentStepIndex == 0 || _submitting ? null : _onBack,
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: null,
            child: Text(
              'Back',
              style: TextStyle(
                color: _currentStepIndex == 0 || _submitting
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemPink,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CupertinoButton(
            onPressed: _submitting
                ? null
                : isLastStep
                ? _submit
                : _onNext,
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: CupertinoColors.systemPink,
            child: _submitting
                ? const CupertinoActivityIndicator(
                    color: CupertinoColors.white,
                    radius: 10,
                  )
                : Text(isLastStep ? 'Create Profile' : l10n.profileNext),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    Widget stepContent = _buildStepContent();

    return PopScope(
      canPop: !_submitting && _currentStepIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_submitting) {
          if (_currentStepIndex == 0) {
            if (mounted) context.go('/onboarding');
          } else {
            _onBack();
          }
        }
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          leading: _currentStepIndex > 0
              ? CupertinoNavigationBarBackButton(onPressed: _onBack)
              : null,
          middle: Text(
            'Profile Setup',
            style: theme.textTheme.navTitleTextStyle,
          ),
          trailing: Text(
            '${_currentStepIndex + 1}/${StepInfo.allSteps.length}',
            style: theme.textTheme.textStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: FadeThrough(
                  delay: AppMotionDurations.fast,
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildHeader(context),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemRed.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: CupertinoColors.systemRed.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _error ?? '',
                                  style: theme.textTheme.textStyle.copyWith(
                                    color: CupertinoColors.systemRed,
                                    fontSize: 16,
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
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Controls outside the form to avoid interference
              Container(
                padding: const EdgeInsets.all(24),
                child: _buildControls(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
