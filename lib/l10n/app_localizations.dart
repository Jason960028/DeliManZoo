import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

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
    Locale('ko'),
  ];

  /// Title for restaurant detail screen
  ///
  /// In en, this message translates to:
  /// **'Restaurant Details'**
  String get restaurantDetail;

  /// Label for business hours section
  ///
  /// In en, this message translates to:
  /// **'Business Hours'**
  String get businessHours;

  /// Status when restaurant is currently open
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get openNow;

  /// Status when restaurant is currently closed
  ///
  /// In en, this message translates to:
  /// **'Closed Now'**
  String get closedNow;

  /// Message when business hours info is not available
  ///
  /// In en, this message translates to:
  /// **'No business hours information available.'**
  String get noBusinessHoursInfo;

  /// Message when business hours cannot be parsed
  ///
  /// In en, this message translates to:
  /// **'Unable to load business hours information.'**
  String get cannotLoadBusinessHours;

  /// Label for contact section
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// Label for website link
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Label for location/map section
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Label for reviews section
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// Message shown while reviews are being loaded
  ///
  /// In en, this message translates to:
  /// **'Loading reviews...'**
  String get loadingReviews;

  /// Error message when phone call cannot be made
  ///
  /// In en, this message translates to:
  /// **'Unable to make phone call'**
  String get cannotMakeCall;

  /// Error message when website cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Unable to open website'**
  String get cannotOpenWebsite;

  /// Message when restaurant is added to favorites
  ///
  /// In en, this message translates to:
  /// **'{restaurantName} has been added to favorites'**
  String addedToFavorites(String restaurantName);

  /// Message when navigating to review screen
  ///
  /// In en, this message translates to:
  /// **'Navigate to review writing screen'**
  String get navigateToReview;
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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
