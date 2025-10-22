import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_ps.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
    Locale('ps'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Aroosi'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Sacred Connections, Blessed Unions'**
  String get tagline;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Aroosi'**
  String get onboardingWelcome;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find your perfect match through cultural harmony and family values'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @profileCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get profileCreateProfile;

  /// No description provided for @profileBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Share Your Sacred Identity'**
  String get profileBasicInfo;

  /// No description provided for @profileLocation.
  ///
  /// In en, this message translates to:
  /// **'Your Sacred Place on Earth'**
  String get profileLocation;

  /// No description provided for @profilePhysical.
  ///
  /// In en, this message translates to:
  /// **'Your Divine Attributes'**
  String get profilePhysical;

  /// No description provided for @profileProfessional.
  ///
  /// In en, this message translates to:
  /// **'Your Path of Knowledge'**
  String get profileProfessional;

  /// No description provided for @profileCultural.
  ///
  /// In en, this message translates to:
  /// **'Your Cultural Roots'**
  String get profileCultural;

  /// No description provided for @profileLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Your Heart\'s True Desires'**
  String get profileLifestyle;

  /// No description provided for @profileAboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get profileAboutMe;

  /// No description provided for @profilePhotos.
  ///
  /// In en, this message translates to:
  /// **'Reflect Your Soul'**
  String get profilePhotos;

  /// No description provided for @profileReview.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Sacred Profile'**
  String get profileReview;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileFullName;

  /// No description provided for @profileDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get profileDateOfBirth;

  /// No description provided for @profileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGender;

  /// No description provided for @profileLookingFor.
  ///
  /// In en, this message translates to:
  /// **'Looking For'**
  String get profileLookingFor;

  /// No description provided for @profileReligion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get profileReligion;

  /// No description provided for @profileMotherTongue.
  ///
  /// In en, this message translates to:
  /// **'Mother Tongue'**
  String get profileMotherTongue;

  /// No description provided for @profileEthnicity.
  ///
  /// In en, this message translates to:
  /// **'Ethnicity'**
  String get profileEthnicity;

  /// No description provided for @profileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCity;

  /// No description provided for @profileCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get profileCountry;

  /// No description provided for @profileHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileHeight;

  /// No description provided for @profileMaritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital Status'**
  String get profileMaritalStatus;

  /// No description provided for @profileEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get profileEducation;

  /// No description provided for @profileOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get profileOccupation;

  /// No description provided for @profileAnnualIncome.
  ///
  /// In en, this message translates to:
  /// **'Annual Income'**
  String get profileAnnualIncome;

  /// No description provided for @profilePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get profilePhoneNumber;

  /// No description provided for @profileDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get profileDiet;

  /// No description provided for @profileSmoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get profileSmoking;

  /// No description provided for @profileDrinking.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get profileDrinking;

  /// No description provided for @profilePhysicalStatus.
  ///
  /// In en, this message translates to:
  /// **'Physical Status'**
  String get profilePhysicalStatus;

  /// No description provided for @profileFamilyRole.
  ///
  /// In en, this message translates to:
  /// **'Family Role'**
  String get profileFamilyRole;

  /// No description provided for @profileFamilyValues.
  ///
  /// In en, this message translates to:
  /// **'Family Values'**
  String get profileFamilyValues;

  /// No description provided for @profileFamilyBackground.
  ///
  /// In en, this message translates to:
  /// **'Family Background'**
  String get profileFamilyBackground;

  /// No description provided for @profileRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get profileRequired;

  /// No description provided for @profileOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get profileOptional;

  /// No description provided for @profileNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get profileNext;

  /// No description provided for @profileBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get profileBack;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileEdit;

  /// No description provided for @sacredCircleTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Sacred Circle'**
  String get sacredCircleTitle;

  /// No description provided for @sacredCircleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect families through traditional values and cultural harmony'**
  String get sacredCircleSubtitle;

  /// No description provided for @sacredCircleFamiliesConnected.
  ///
  /// In en, this message translates to:
  /// **'Families Connected'**
  String get sacredCircleFamiliesConnected;

  /// No description provided for @sacredCircleFamilyUnity.
  ///
  /// In en, this message translates to:
  /// **'Unity'**
  String get sacredCircleFamilyUnity;

  /// No description provided for @sacredCircleCulturalHarmony.
  ///
  /// In en, this message translates to:
  /// **'Cultural Harmony'**
  String get sacredCircleCulturalHarmony;

  /// No description provided for @sacredCircleRequestFamilyIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Request Family Introduction'**
  String get sacredCircleRequestFamilyIntroduction;

  /// No description provided for @sacredCircleBeginSupervisedCourtship.
  ///
  /// In en, this message translates to:
  /// **'Begin Supervised Courtship'**
  String get sacredCircleBeginSupervisedCourtship;

  /// No description provided for @sacredCircleViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get sacredCircleViewDetails;

  /// No description provided for @sacredCircleSendBlessing.
  ///
  /// In en, this message translates to:
  /// **'Send Blessing'**
  String get sacredCircleSendBlessing;

  /// No description provided for @compatibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Compatibility Analysis'**
  String get compatibilityTitle;

  /// No description provided for @compatibilityAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing compatibility...'**
  String get compatibilityAnalyzing;

  /// No description provided for @compatibilityNoData.
  ///
  /// In en, this message translates to:
  /// **'No Compatibility Data'**
  String get compatibilityNoData;

  /// No description provided for @compatibilityOverall.
  ///
  /// In en, this message translates to:
  /// **'Cultural Compatibility'**
  String get compatibilityOverall;

  /// No description provided for @compatibilityExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent cultural harmony - strong foundation for a blessed union'**
  String get compatibilityExcellent;

  /// No description provided for @compatibilityGood.
  ///
  /// In en, this message translates to:
  /// **'Good cultural compatibility with areas for understanding'**
  String get compatibilityGood;

  /// No description provided for @compatibilityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate compatibility - open communication essential'**
  String get compatibilityModerate;

  /// No description provided for @compatibilityLow.
  ///
  /// In en, this message translates to:
  /// **'Cultural differences may require significant adaptation'**
  String get compatibilityLow;

  /// No description provided for @compatibilityReligion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get compatibilityReligion;

  /// No description provided for @compatibilityLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get compatibilityLanguage;

  /// No description provided for @compatibilityCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get compatibilityCulture;

  /// No description provided for @compatibilityFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get compatibilityFamily;

  /// No description provided for @compatibilityInsights.
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get compatibilityInsights;

  /// No description provided for @compatibilityRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get compatibilityRecommendations;

  /// No description provided for @compatibilityFamilyApproval.
  ///
  /// In en, this message translates to:
  /// **'Request Family Approval'**
  String get compatibilityFamilyApproval;

  /// No description provided for @compatibilitySupervisedConversation.
  ///
  /// In en, this message translates to:
  /// **'Begin Supervised Courtship'**
  String get compatibilitySupervisedConversation;

  /// No description provided for @familyApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Approval'**
  String get familyApprovalTitle;

  /// No description provided for @familyApprovalSent.
  ///
  /// In en, this message translates to:
  /// **'Sent Requests'**
  String get familyApprovalSent;

  /// No description provided for @familyApprovalReceived.
  ///
  /// In en, this message translates to:
  /// **'Received Requests'**
  String get familyApprovalReceived;

  /// No description provided for @familyApprovalRequest.
  ///
  /// In en, this message translates to:
  /// **'Request Family Introduction'**
  String get familyApprovalRequest;

  /// No description provided for @familyApprovalRespond.
  ///
  /// In en, this message translates to:
  /// **'Respond to Request'**
  String get familyApprovalRespond;

  /// No description provided for @familyApprovalApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get familyApprovalApprove;

  /// No description provided for @familyApprovalDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get familyApprovalDeny;

  /// No description provided for @familyApprovalPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get familyApprovalPending;

  /// No description provided for @familyApprovalApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get familyApprovalApproved;

  /// No description provided for @familyApprovalDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get familyApprovalDenied;

  /// No description provided for @familyApprovalExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get familyApprovalExpired;

  /// No description provided for @familyApprovalRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get familyApprovalRelationship;

  /// No description provided for @familyApprovalMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get familyApprovalMessage;

  /// No description provided for @familyApprovalResponseMessage.
  ///
  /// In en, this message translates to:
  /// **'Response Message'**
  String get familyApprovalResponseMessage;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelp;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About Aroosi'**
  String get settingsAbout;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settingsLogout;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccount;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get commonFilter;

  /// No description provided for @commonSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get commonSort;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @errorsNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errorsNetwork;

  /// No description provided for @errorsServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errorsServer;

  /// No description provided for @errorsUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized. Please log in again.'**
  String get errorsUnauthorized;

  /// No description provided for @errorsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get errorsNotFound;

  /// No description provided for @errorsGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorsGeneric;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get validationRequired;

  /// No description provided for @validationInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get validationInvalidEmail;

  /// No description provided for @validationInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get validationInvalidPhone;

  /// No description provided for @validationTooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short'**
  String get validationTooShort;

  /// No description provided for @validationTooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long'**
  String get validationTooLong;

  /// No description provided for @validationInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid format'**
  String get validationInvalidFormat;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa', 'ps'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
    case 'ps':
      return AppLocalizationsPs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
