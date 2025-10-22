import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';
import 'package:aroosi_flutter/features/cultural/cultural_constants.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/primary_button.dart';

class CulturalSearchFiltersScreen extends ConsumerStatefulWidget {
  final SearchFilters currentFilters;
  final Function(SearchFilters) onFiltersChanged;

  const CulturalSearchFiltersScreen({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  ConsumerState<CulturalSearchFiltersScreen> createState() => _CulturalSearchFiltersScreenState();
}

class _CulturalSearchFiltersScreenState extends ConsumerState<CulturalSearchFiltersScreen> {
  // Local state for filters
  String? _religion;
  String? _religiousPractice;
  String? _motherTongue;
  final Set<String> _languages = {};
  String? _familyValues;
  String? _marriageViews;
  String? _ethnicity;
  int? _minReligionImportance;
  int? _maxReligionImportance;
  int? _minCultureImportance;
  int? _maxCultureImportance;

  @override
  void initState() {
    super.initState();
    // Initialize with current filters
    _religion = widget.currentFilters.religion;
    _religiousPractice = widget.currentFilters.religiousPractice;
    _motherTongue = widget.currentFilters.motherTongue;
    _languages.addAll(widget.currentFilters.languages ?? []);
    _familyValues = widget.currentFilters.familyValues;
    _marriageViews = widget.currentFilters.marriageViews;
    _ethnicity = widget.currentFilters.ethnicity;
    _minReligionImportance = widget.currentFilters.minReligionImportance;
    _maxReligionImportance = widget.currentFilters.maxReligionImportance;
    _minCultureImportance = widget.currentFilters.minCultureImportance;
    _maxCultureImportance = widget.currentFilters.maxCultureImportance;
  }

  void _applyFilters() {
    final updatedFilters = widget.currentFilters.copyWith(
      religion: _religion,
      religiousPractice: _religiousPractice,
      motherTongue: _motherTongue,
      languages: _languages.isNotEmpty ? _languages.toList() : null,
      familyValues: _familyValues,
      marriageViews: _marriageViews,
      ethnicity: _ethnicity,
      minReligionImportance: _minReligionImportance,
      maxReligionImportance: _maxReligionImportance,
      minCultureImportance: _minCultureImportance,
      maxCultureImportance: _maxCultureImportance,
    );

    widget.onFiltersChanged(updatedFilters);
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _religion = null;
      _religiousPractice = null;
      _motherTongue = null;
      _languages.clear();
      _familyValues = null;
      _marriageViews = null;
      _ethnicity = null;
      _minReligionImportance = null;
      _maxReligionImportance = null;
      _minCultureImportance = null;
      _maxCultureImportance = null;
    });
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String? value,
    required List<String> options,
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
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            underline: const SizedBox.shrink(),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Any'),
              ),
              ...options.where((option) => option.isNotEmpty).map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(displayName(option)),
                );
              }),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectFilter({
    required String label,
    required Set<String> selectedValues,
    required List<String> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return FilterChip(
              label: Text(option.replaceAll('_', ' ').toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedValues.add(option);
                  } else {
                    selectedValues.remove(option);
                  }
                });
              },
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImportanceRangeFilter({
    required String label,
    required int? minValue,
    required int? maxValue,
    required void Function(int?) onMinChanged,
    required void Function(int?) onMaxChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Minimum', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: minValue,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      underline: const SizedBox.shrink(),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Any'),
                        ),
                        ...List.generate(10, (i) => i + 1).map((value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value'),
                          );
                        }),
                      ],
                      onChanged: onMinChanged,
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
                  const Text('Maximum', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: maxValue,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      underline: const SizedBox.shrink(),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Any'),
                        ),
                        ...List.generate(10, (i) => i + 1).map((value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value'),
                          );
                        }),
                      ],
                      onChanged: onMaxChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cultural Filters',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find culturally compatible matches',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Filter by religious background, cultural values, and family traditions.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Religious Background
            _buildSection(
              title: 'Religious Background',
              subtitle: 'Find matches with compatible religious values',
              children: [
                _buildDropdownFilter(
                  label: 'Religion',
                  value: _religion,
                  options: religionOptions,
                  onChanged: (value) => setState(() => _religion = value),
                  displayName: getReligionDisplayName,
                ),
                const SizedBox(height: 16),
                _buildDropdownFilter(
                  label: 'Religious Practice',
                  value: _religiousPractice,
                  options: religiousPracticeOptions,
                  onChanged: (value) => setState(() => _religiousPractice = value),
                  displayName: getReligiousPracticeDisplayName,
                ),
                const SizedBox(height: 16),
                _buildImportanceRangeFilter(
                  label: 'Religion Importance (1-10)',
                  minValue: _minReligionImportance,
                  maxValue: _maxReligionImportance,
                  onMinChanged: (value) => setState(() => _minReligionImportance = value),
                  onMaxChanged: (value) => setState(() => _maxReligionImportance = value),
                ),
              ],
            ),

            // Language & Communication
            _buildSection(
              title: 'Language & Communication',
              subtitle: 'Connect with people who speak your language',
              children: [
                _buildDropdownFilter(
                  label: 'Mother Tongue',
                  value: _motherTongue,
                  options: motherTongueOptions,
                  onChanged: (value) => setState(() => _motherTongue = value),
                  displayName: (value) => value.replaceAll('_', ' ').toUpperCase(),
                ),
                const SizedBox(height: 16),
                _buildMultiSelectFilter(
                  label: 'Languages Spoken',
                  selectedValues: _languages,
                  options: languagesSpokenOptions,
                ),
              ],
            ),

            // Cultural Values & Family
            _buildSection(
              title: 'Cultural Values & Family',
              subtitle: 'Find matches with similar family values and traditions',
              children: [
                _buildDropdownFilter(
                  label: 'Family Values',
                  value: _familyValues,
                  options: familyValuesOptions,
                  onChanged: (value) => setState(() => _familyValues = value),
                  displayName: getFamilyValuesDisplayName,
                ),
                const SizedBox(height: 16),
                _buildDropdownFilter(
                  label: 'Marriage Views',
                  value: _marriageViews,
                  options: marriageViewsOptions,
                  onChanged: (value) => setState(() => _marriageViews = value),
                  displayName: getMarriageViewsDisplayName,
                ),
                const SizedBox(height: 16),
                _buildImportanceRangeFilter(
                  label: 'Culture Importance (1-10)',
                  minValue: _minCultureImportance,
                  maxValue: _maxCultureImportance,
                  onMinChanged: (value) => setState(() => _minCultureImportance = value),
                  onMaxChanged: (value) => setState(() => _maxCultureImportance = value),
                ),
                const SizedBox(height: 16),
                _buildDropdownFilter(
                  label: 'Ethnicity',
                  value: _ethnicity,
                  options: ethnicityOptions,
                  onChanged: (value) => setState(() => _ethnicity = value),
                  displayName: (value) => value.replaceAll('_', ' ').toUpperCase(),
                ),
              ],
            ),

            // Action Buttons
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    label: 'Apply Filters',
                    onPressed: _applyFilters,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'These filters help find culturally compatible matches for meaningful relationships.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
