import 'package:dartz/dartz.dart'; // Either 타입을 사용하기 위해 dartz 패키지를 임포트
import '../../../../core/error/failure.dart'; // Failure 클래스 임포트
import '../entities/restaurant_entity.dart'; // RestaurantEntity 임포트

abstract class RestaurantRepository {
  /// 지정된 위도와 경도 주변의 음식점 목록을 가져옵니다.
  ///
  /// 성공 시 [RestaurantEntity]의 리스트를 포함하는 Right를 반환합니다.
  /// 실패 시 [Failure]를 포함하는 Left를 반환합니다.
  Future<Either<Failure, List<RestaurantEntity>>> getNearbyRestaurants(
      double lat,
      double lng,
      );
}