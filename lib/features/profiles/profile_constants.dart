/// Centralized profile-related option lists (parity with aroosi-mobile subset)
/// These can be refined or localized later.
library;

const genderOptions = ['male', 'female'];
const preferredGenderOptions = ['male', 'female', 'any'];
const maritalStatusOptions = ['single', 'divorced', 'widowed'];
const physicalStatusOptions = ['normal', 'athletic', 'plus-size'];
const dietOptions = ['veg', 'non-veg', 'vegan', 'halal'];
const smokingOptions = ['no', 'occasionally', 'yes'];
const drinkingOptions = ['no', 'occasionally', 'socially'];
const profileForOptions = ['self', 'sibling', 'child'];

// Example starter ethnicity / religion / mother tongue lists (can expand to match RN fully)
const religionOptions = ['muslim', 'hindu', 'sikh'];
const motherTongueOptions = [
  'pashto',
  'dari',
  'uzbeki',
  'turkmeni',
  'nuristani',
  'balochi',
];
const ethnicityOptions = [
  'pashtun',
  'tajik',
  'hazara',
  'uzbek',
  'turkmen',
  'nuristani',
  'aimaq',
  'baloch',
  'sadat',
];

// Interests placeholder list; in practice these should come from backend or a service.
const defaultInterestSuggestions = [
  'travel',
  'reading',
  'fitness',
  'cooking',
  'music',
  'art',
  'sports',
  'technology',
];
