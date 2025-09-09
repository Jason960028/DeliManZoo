// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get restaurantDetail => '레스토랑 상세정보';

  @override
  String get businessHours => '영업 정보';

  @override
  String get openNow => '영업 중';

  @override
  String get closedNow => '영업 종료';

  @override
  String get noBusinessHoursInfo => '영업시간 정보가 없습니다.';

  @override
  String get cannotLoadBusinessHours => '영업시간 정보를 불러올 수 없습니다.';

  @override
  String get contact => '연락처';

  @override
  String get website => '웹사이트';

  @override
  String get location => '위치';

  @override
  String get reviews => '리뷰';

  @override
  String get loadingReviews => '리뷰를 불러오는 중...';

  @override
  String get cannotMakeCall => '전화를 걸 수 없습니다';

  @override
  String get cannotOpenWebsite => '웹사이트를 열 수 없습니다';

  @override
  String addedToFavorites(String restaurantName) {
    return '$restaurantName을(를) 즐겨찾기에 추가했습니다';
  }

  @override
  String get navigateToReview => '리뷰 작성 화면으로 이동합니다';
}
