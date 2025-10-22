/// Religious options
const List<String> religionOptions = [
  '',
  'islam',
  'christianity',
  'hinduism',
  'sikhism',
  'judaism',
  'buddhism',
  'other',
];

/// Religious practice levels
const List<String> religiousPracticeOptions = [
  '',
  'very_practicing',
  'moderately_practicing',
  'not_practicing',
  'spiritual_but_not_religious',
];

/// Mother tongue / native language options
const List<String> motherTongueOptions = [
  '',
  'arabic',
  'urdu',
  'hindi',
  'persian_farsi',
  'pashto',
  'punjabi',
  'bengali',
  'gujarati',
  'marathi',
  'tamil',
  'telugu',
  'kannada',
  'malayalam',
  'english',
  'french',
  'german',
  'spanish',
  'italian',
  'portuguese',
  'russian',
  'chinese_mandarin',
  'japanese',
  'korean',
  'other',
];

/// Languages spoken options (can select multiple)
const List<String> languagesSpokenOptions = [
  'english',
  'arabic',
  'urdu',
  'hindi',
  'persian_farsi',
  'pashto',
  'punjabi',
  'bengali',
  'gujarati',
  'marathi',
  'tamil',
  'telugu',
  'kannada',
  'malayalam',
  'french',
  'german',
  'spanish',
  'italian',
  'portuguese',
  'russian',
  'chinese_mandarin',
  'japanese',
  'korean',
  'turkish',
  'dutch',
  'swedish',
  'danish',
  'norwegian',
  'finnish',
  'greek',
  'hebrew',
  'other',
];

/// Family values options
const List<String> familyValuesOptions = [
  '',
  'traditional',
  'modern',
  'mixed',
  'liberal',
  'conservative',
];

/// Marriage views options
const List<String> marriageViewsOptions = [
  '',
  'love_marriage',
  'arranged_marriage',
  'both_open',
  'prefer_traditional',
  'prefer_modern',
];

/// Traditional values importance
const List<String> traditionalValuesOptions = [
  '',
  'very_important',
  'somewhat_important',
  'neutral',
  'not_important',
  'not_traditional',
];

/// Family approval importance
const List<String> familyApprovalImportanceOptions = [
  '',
  'very_important',
  'somewhat_important',
  'neutral',
  'not_important',
  'prefer_independence',
];

/// Ethnicity options (common in South Asian/Middle Eastern contexts)
const List<String> ethnicityOptions = [
  '',
  'punjabi',
  'muhajir',
  'sindhi',
  'pashtun',
  'baloch',
  'kashmiri',
  'gujarati',
  'marathi',
  'bengali',
  'tamil',
  'telugu',
  'kannada',
  'malayali',
  'persian',
  'arab',
  'turkish',
  'kurdish',
  'afghan',
  'pakistani',
  'indian',
  'bangladeshi',
  'sri_lankan',
  'other',
];

/// Family relationship options for approval requests
const List<String> familyRelationOptions = [
  'parent',
  'grandparent',
  'sibling',
  'uncle_aunt',
  'cousin',
  'guardian',
  'family_friend',
  'other',
];

/// Supervised conversation rules
const List<String> conversationRulesOptions = [
  'no_personal_contact_info',
  'no_inappropriate_topics',
  'respect_cultural_boundaries',
  'maintain_decorum',
  'family_values_focused',
  'marriage_intention_only',
  'supervised_responses_only',
];

/// Topic restrictions for supervised conversations
const List<String> topicRestrictionOptions = [
  'romantic_relationships',
  'physical_attraction',
  'personal_finances',
  'political_views',
  'religious_debates',
  'family_conflicts',
  'personal_problems',
  'inappropriate_jokes',
  'cultural_taboos',
];

/// Cultural compatibility scoring weights (1-10 scale)
class CulturalWeights {
  static const double religionWeight = 8.0;
  static const double religiousPracticeWeight = 7.0;
  static const double motherTongueWeight = 6.0;
  static const double languagesWeight = 4.0;
  static const double familyValuesWeight = 9.0;
  static const double marriageViewsWeight = 8.0;
  static const double traditionalValuesWeight = 7.0;
  static const double ethnicityWeight = 5.0;
}

/// Display names for user-friendly labels
const Map<String, String> religionDisplayNames = {
  'islam': 'Islam',
  'christianity': 'Christianity',
  'hinduism': 'Hinduism',
  'sikhism': 'Sikhism',
  'judaism': 'Judaism',
  'buddhism': 'Buddhism',
  'other': 'Other',
};

const Map<String, String> religiousPracticeDisplayNames = {
  'very_practicing': 'Very Practicing',
  'moderately_practicing': 'Moderately Practicing',
  'not_practicing': 'Not Practicing',
  'spiritual_but_not_religious': 'Spiritual but Not Religious',
};

const Map<String, String> familyValuesDisplayNames = {
  'traditional': 'Traditional',
  'modern': 'Modern',
  'mixed': 'Mixed',
  'liberal': 'Liberal',
  'conservative': 'Conservative',
};

const Map<String, String> marriageViewsDisplayNames = {
  'love_marriage': 'Love Marriage',
  'arranged_marriage': 'Arranged Marriage',
  'both_open': 'Open to Both',
  'prefer_traditional': 'Prefer Traditional',
  'prefer_modern': 'Prefer Modern',
};

const Map<String, String> traditionalValuesDisplayNames = {
  'very_important': 'Very Important',
  'somewhat_important': 'Somewhat Important',
  'neutral': 'Neutral',
  'not_important': 'Not Important',
  'not_traditional': 'Not Traditional',
};

const Map<String, String> familyApprovalImportanceDisplayNames = {
  'very_important': 'Very Important',
  'somewhat_important': 'Somewhat Important',
  'neutral': 'Neutral',
  'not_important': 'Not Important',
  'prefer_independence': 'Prefer Independence',
};

/// Helper functions for getting display names
String getReligionDisplayName(String? value) {
  if (value == null || value.isEmpty) return '';
  return religionDisplayNames[value] ?? value;
}

String getReligiousPracticeDisplayName(String? value) {
  if (value == null || value.isEmpty) return '';
  return religiousPracticeDisplayNames[value] ?? value;
}

String getFamilyValuesDisplayName(String? value) {
  if (value == null || value.isEmpty) return '';
  return familyValuesDisplayNames[value] ?? value;
}

String getMarriageViewsDisplayName(String? value) {
  if (value == null || value.isEmpty) return '';
  return marriageViewsDisplayNames[value] ?? value;
}

String getTraditionalValuesDisplayName(String? value) {
  if (value == null || value.isEmpty) return '';
  return traditionalValuesDisplayNames[value] ?? value;
}

String getFamilyApprovalImportanceDisplayName(String? value) {
  if (value == null || value.isEmpty) return '';
  return familyApprovalImportanceDisplayNames[value] ?? value;
}

/// Validation helpers
bool isValidReligion(String? value) => religionOptions.contains(value);
bool isValidReligiousPractice(String? value) =>
    religiousPracticeOptions.contains(value);
bool isValidMotherTongue(String? value) => motherTongueOptions.contains(value);
bool isValidFamilyValues(String? value) => familyValuesOptions.contains(value);
bool isValidMarriageViews(String? value) =>
    marriageViewsOptions.contains(value);
bool isValidTraditionalValues(String? value) =>
    traditionalValuesOptions.contains(value);
bool isValidFamilyApprovalImportance(String? value) =>
    familyApprovalImportanceOptions.contains(value);
bool isValidEthnicity(String? value) => ethnicityOptions.contains(value);
