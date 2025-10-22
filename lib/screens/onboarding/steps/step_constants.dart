import 'package:flutter/material.dart';

/// Constants used across onboarding steps
class StepConstants {
  // Field names
  static const String fullName = 'fullName';
  static const String dateOfBirth = 'dateOfBirth';
  static const String gender = 'gender';
  static const String preferredGender = 'preferredGender';
  static const String profileFor = 'profileFor';
  static const String country = 'country';
  static const String city = 'city';
  static const String height = 'height';
  static const String maritalStatus = 'maritalStatus';
  static const String physicalStatus = 'physicalStatus';
  static const String education = 'education';
  static const String occupation = 'occupation';
  static const String annualIncome = 'annualIncome';
  static const String religion = 'religion';
  static const String motherTongue = 'motherTongue';
  static const String ethnicity = 'ethnicity';
  static const String aboutMe = 'aboutMe';
  static const String phoneNumber = 'phoneNumber';
  static const String diet = 'diet';
  static const String smoking = 'smoking';
  static const String drinking = 'drinking';
  static const String partnerPreferenceAgeMin = 'partnerPreferenceAgeMin';
  static const String partnerPreferenceAgeMax = 'partnerPreferenceAgeMax';
  static const String partnerPreferenceCity = 'partnerPreferenceCity';
  static const String profileImageIds = 'profileImageIds';

  // Default values
  static const String defaultCountry = 'UK';
  static const String defaultProfileFor = 'self';
  static const String defaultPhysicalStatus = 'normal';
  static const String defaultDialCode = '+44';

  // Validation constants
  static const int minimumAge = 18;
  static const int maximumAge = 120;
  static const int minimumHeight = 100;
  static const int maximumHeight = 250;
  static const int minimumNameLength = 2;
  static const int maximumNameLength = 50;
  static const int minimumAboutMeWords = 10;
  static const int minimumCityLength = 2;
  static const int maximumCityLength = 50;
  static const int minimumIncome = 0;
  static const int maximumIncome = 1000000;
  static const int maximumPhotos = 5;
  static const int minimumAboutMeLength = 50;
  static const int maximumAboutMeLength = 2000;
}

/// Enum for onboarding steps
enum OnboardingStep {
  basicInfo,
  location,
  physicalDetails,
  professional,
  cultural,
  aboutMe,
  lifestyle,
  photos,
}

/// Step information
class StepInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final int index;

  const StepInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.index,
  });

  static const List<StepInfo> allSteps = [
    StepInfo(
      title: 'Basic Info',
      subtitle: 'Tell us about yourself',
      icon: Icons.person_rounded,
      index: 0,
    ),
    StepInfo(
      title: 'Location',
      subtitle: 'Where are you based?',
      icon: Icons.location_on_rounded,
      index: 1,
    ),
    StepInfo(
      title: 'Physical Details',
      subtitle: 'Your physical attributes',
      icon: Icons.accessibility_rounded,
      index: 2,
    ),
    StepInfo(
      title: 'Professional',
      subtitle: 'Your career & education',
      icon: Icons.work_rounded,
      index: 3,
    ),
    StepInfo(
      title: 'Cultural',
      subtitle: 'Your cultural background',
      icon: Icons.diversity_3_rounded,
      index: 4,
    ),
    StepInfo(
      title: 'About Me',
      subtitle: 'Describe yourself',
      icon: Icons.description_rounded,
      index: 5,
    ),
    StepInfo(
      title: 'Lifestyle',
      subtitle: 'Your preferences',
      icon: Icons.favorite_rounded,
      index: 6,
    ),
    StepInfo(
      title: 'Photos',
      subtitle: 'Add your profile photos',
      icon: Icons.photo_camera_rounded,
      index: 7,
    ),
  ];

  static StepInfo getStep(int index) {
    if (index >= 0 && index < allSteps.length) {
      return allSteps[index];
    }
    return allSteps.first;
  }
}

/// Option types for dropdowns
class OptionTypes {
  // Gender options
  static const List<String> genderOptions = ['male', 'female', 'other'];

  // Preferred gender options
  static const List<String> preferredGenderOptions = [
    'male',
    'female',
    'both',
    'other',
  ];

  // Marital status options
  static const List<String> maritalStatusOptions = [
    'single',
    'divorced',
    'widowed',
    'separated',
  ];

  // Diet options
  static const List<String> dietOptions = [
    'vegetarian',
    'non-vegetarian',
    'vegan',
    'halal',
    'kosher',
  ];

  // Smoking/drinking options
  static const List<String> smokingDrinkingOptions = [
    'never',
    'occasionally',
    'socially',
    'regularly',
  ];

  // Physical status options
  static const List<String> physicalStatusOptions = [
    'normal',
    'differently-abled',
  ];

  // Profile for options
  static const List<String> profileForOptions = ['self', 'friend', 'family'];

  // Religion options
  static const List<String> religionOptions = [
    '',
    'islam',
    'christianity',
    'hinduism',
    'sikhism',
    'judaism',
    'other',
  ];

  // Mother tongue options
  static const List<String> motherTongueOptions = [
    '',
    'pashto',
    'dari',
    'urdu',
    'english',
    'farsi',
    'hindi',
    'other',
  ];

  // Country options
  static const List<String> countryOptions = [
    'UK',
    'USA',
    'Canada',
    'Germany',
    'France',
    'Other',
  ];
}
