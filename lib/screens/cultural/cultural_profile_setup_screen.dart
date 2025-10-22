import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/features/cultural/cultural_controller.dart';
import 'package:aroosi_flutter/features/cultural/cultural_constants.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';
import 'package:aroosi_flutter/theme/colors.dart';

import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/input_field.dart';
import 'package:aroosi_flutter/widgets/primary_button.dart';

class CulturalProfileSetupScreen extends ConsumerStatefulWidget {
  const CulturalProfileSetupScreen({super.key});

  @override
  ConsumerState<CulturalProfileSetupScreen> createState() =>
      _CulturalProfileSetupScreenState();
}

class _CulturalProfileSetupScreenState
    extends ConsumerState<CulturalProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyBackgroundCtrl = TextEditingController();
  final _ethnicityCtrl = TextEditingController();

  // Selected values
  String? _selectedReligion;
  String? _selectedReligiousPractice;
  String? _selectedMotherTongue;
  final Set<String> _selectedLanguages = {};
  String? _selectedFamilyValues;
  String? _selectedMarriageViews;
  String? _selectedTraditionalValues;
  String? _selectedFamilyApprovalImportance;
  double _religionImportance = 5.0;
  double _cultureImportance = 5.0;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _familyBackgroundCtrl.dispose();
    _ethnicityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.profile?.id != null) {
      await ref
          .read(culturalControllerProvider.notifier)
          .loadCulturalProfile(authState.profile!.id);
      final culturalState = ref.read(culturalControllerProvider);
      if (culturalState.culturalProfile != null) {
        _populateFromProfile(culturalState.culturalProfile!);
      }
    }
  }

  void _populateFromProfile(CulturalProfile profile) {
    setState(() {
      _selectedReligion = profile.religion;
      _selectedReligiousPractice = profile.religiousPractice;
      _selectedMotherTongue = profile.motherTongue;
      _selectedLanguages.clear();
      _selectedLanguages.addAll(profile.languages);
      _selectedFamilyValues = profile.familyValues;
      _selectedMarriageViews = profile.marriageViews;
      _selectedTraditionalValues = profile.traditionalValues;
      _selectedFamilyApprovalImportance = profile.familyApprovalImportance;
      _religionImportance = profile.religionImportance.toDouble();
      _cultureImportance = profile.cultureImportance.toDouble();
      _familyBackgroundCtrl.text = profile.familyBackground ?? '';
      _ethnicityCtrl.text = profile.ethnicity ?? '';
    });
  }

  BoxDecoration cupertinoDecoration(
    BuildContext context, {
    bool hasError = false,
  }) {
    return BoxDecoration(
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      border: Border.all(
        color: hasError ? CupertinoColors.destructiveRed : AppColors.primary,
        width: 1.5,
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

  Future<void> _showPickerModal(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String? currentValue,
    required void Function(String?) onSelected,
    required String Function(String) displayName,
  }) async {
    String? selectedValue = currentValue;

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Done'),
                    onPressed: () {
                      onSelected(selectedValue);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                onSelectedItemChanged: (int index) {
                  selectedValue = options[index];
                },
                children: options.map((option) {
                  return Center(
                    child: Text(
                      option.isEmpty ? 'Select...' : displayName(option),
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCupertinoDropdownField({
    required String label,
    required String? value,
    required List<String> options,
    required String? Function(String?) validator,
    required void Function(String?) onChanged,
    required String Function(String) displayName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showPickerModal(
            context,
            title: label,
            options: options,
            currentValue: value,
            onSelected: onChanged,
            displayName: displayName,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: cupertinoDecoration(context).copyWith(
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value == null || value.isEmpty
                      ? 'Select...'
                      : displayName(value),
                  style: TextStyle(
                    color: value == null || value.isEmpty
                        ? CupertinoColors.placeholderText
                        : CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCupertinoMultiSelectField({
    required String label,
    required Set<String> selectedValues,
    required List<String> options,
    required void Function(Set<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return GestureDetector(
              onTap: () {
                final newSelection = Set<String>.from(selectedValues);
                if (isSelected) {
                  newSelection.remove(option);
                } else {
                  newSelection.add(option);
                }
                onChanged(newSelection);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : CupertinoTheme.of(context).scaffoldBackgroundColor,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  option.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: isSelected
                        ? CupertinoColors.white
                        : AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCupertinoSliderField({
    required String label,
    required double value,
    required void Function(double) onChanged,
    required String Function(double) displayValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              displayValue(value),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoSlider(
          value: value,
          min: 1,
          max: 10,
          divisions: 9,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final authState = ref.read(authControllerProvider);
    if (!authState.isAuthenticated || authState.profile?.id == null) {
      setState(() {
        _loading = false;
        _error = 'User not authenticated';
      });
      return;
    }

    final culturalProfile = CulturalProfile(
      religion: _selectedReligion,
      religiousPractice: _selectedReligiousPractice,
      motherTongue: _selectedMotherTongue,
      languages: _selectedLanguages.toList(),
      familyValues: _selectedFamilyValues,
      marriageViews: _selectedMarriageViews,
      traditionalValues: _selectedTraditionalValues,
      familyApprovalImportance: _selectedFamilyApprovalImportance,
      religionImportance: _religionImportance.toInt(),
      cultureImportance: _cultureImportance.toInt(),
      familyBackground: _familyBackgroundCtrl.text.trim().isEmpty
          ? null
          : _familyBackgroundCtrl.text.trim(),
      ethnicity: _ethnicityCtrl.text.trim().isEmpty
          ? null
          : _ethnicityCtrl.text.trim(),
    );

    final success = await ref
        .read(culturalControllerProvider.notifier)
        .updateCulturalProfile(authState.profile!.id, culturalProfile);

    setState(() {
      _loading = false;
      _error = success ? null : 'Failed to save cultural profile';
    });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cultural profile saved successfully!')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final culturalState = ref.watch(culturalControllerProvider);

    return AppScaffold(
      title: 'Cultural Profile',
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about your cultural background',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This helps us find culturally compatible matches for meaningful relationships.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Religion Section
              Text(
                'Religious Background',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              _buildCupertinoDropdownField(
                label: 'Religion',
                value: _selectedReligion,
                options: religionOptions,
                validator: (value) => null, // Optional field
                onChanged: (value) => setState(() => _selectedReligion = value),
                displayName: getReligionDisplayName,
              ),

              _buildCupertinoDropdownField(
                label: 'Religious Practice',
                value: _selectedReligiousPractice,
                options: religiousPracticeOptions,
                validator: (value) => null,
                onChanged: (value) =>
                    setState(() => _selectedReligiousPractice = value),
                displayName: getReligiousPracticeDisplayName,
              ),

              _buildCupertinoSliderField(
                label: 'Importance of Religion in Match',
                value: _religionImportance,
                onChanged: (value) =>
                    setState(() => _religionImportance = value),
                displayValue: (value) => '${value.toInt()}/10',
              ),

              const SizedBox(height: 24),

              // Language Section
              Text(
                'Language & Communication',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              _buildCupertinoDropdownField(
                label: 'Mother Tongue / Native Language',
                value: _selectedMotherTongue,
                options: motherTongueOptions,
                validator: (value) => null,
                onChanged: (value) =>
                    setState(() => _selectedMotherTongue = value),
                displayName: (value) =>
                    value.replaceAll('_', ' ').toUpperCase(),
              ),

              _buildCupertinoMultiSelectField(
                label: 'Languages You Speak',
                selectedValues: _selectedLanguages,
                options: languagesSpokenOptions,
                onChanged: (values) {
                  setState(() {
                    _selectedLanguages.clear();
                    _selectedLanguages.addAll(values);
                  });
                },
              ),

              const SizedBox(height: 24),

              // Cultural Values Section
              Text(
                'Cultural Values & Family',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              _buildCupertinoDropdownField(
                label: 'Family Values',
                value: _selectedFamilyValues,
                options: familyValuesOptions,
                validator: (value) => null,
                onChanged: (value) =>
                    setState(() => _selectedFamilyValues = value),
                displayName: getFamilyValuesDisplayName,
              ),

              _buildCupertinoDropdownField(
                label: 'Marriage Views',
                value: _selectedMarriageViews,
                options: marriageViewsOptions,
                validator: (value) => null,
                onChanged: (value) =>
                    setState(() => _selectedMarriageViews = value),
                displayName: getMarriageViewsDisplayName,
              ),

              _buildCupertinoDropdownField(
                label: 'Importance of Family Approval',
                value: _selectedFamilyApprovalImportance,
                options: familyApprovalImportanceOptions,
                validator: (value) => null,
                onChanged: (value) =>
                    setState(() => _selectedFamilyApprovalImportance = value),
                displayName: getFamilyApprovalImportanceDisplayName,
              ),

              _buildCupertinoDropdownField(
                label: 'Traditional Values',
                value: _selectedTraditionalValues,
                options: traditionalValuesOptions,
                validator: (value) => null,
                onChanged: (value) =>
                    setState(() => _selectedTraditionalValues = value),
                displayName: getTraditionalValuesDisplayName,
              ),

              _buildCupertinoSliderField(
                label: 'Importance of Culture in Match',
                value: _cultureImportance,
                onChanged: (value) =>
                    setState(() => _cultureImportance = value),
                displayValue: (value) => '${value.toInt()}/10',
              ),

              // Additional Fields
              InputField(
                controller: _ethnicityCtrl,
                label: 'Ethnicity (Optional)',
              ),
              const SizedBox(height: 16),

              InputField(
                controller: _familyBackgroundCtrl,
                label: 'Family Background (Optional)',
                keyboardType: TextInputType.multiline,
              ),

              const SizedBox(height: 32),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),

              PrimaryButton(
                label: 'Save Cultural Profile',
                loading: _loading || culturalState.loading,
                onPressed: _saveProfile,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
