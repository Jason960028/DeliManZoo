// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get restaurantDetail => 'Restaurant Details';

  @override
  String get businessHours => 'Business Hours';

  @override
  String get openNow => 'Open Now';

  @override
  String get closedNow => 'Closed Now';

  @override
  String get noBusinessHoursInfo => 'No business hours information available.';

  @override
  String get cannotLoadBusinessHours =>
      'Unable to load business hours information.';

  @override
  String get contact => 'Contact';

  @override
  String get website => 'Website';

  @override
  String get location => 'Location';

  @override
  String get reviews => 'Reviews';

  @override
  String get loadingReviews => 'Loading reviews...';

  @override
  String get cannotMakeCall => 'Unable to make phone call';

  @override
  String get cannotOpenWebsite => 'Unable to open website';

  @override
  String addedToFavorites(String restaurantName) {
    return '$restaurantName has been added to favorites';
  }

  @override
  String get navigateToReview => 'Navigate to review writing screen';
}
