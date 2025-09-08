import 'package:dartz/dartz.dart'; // Either 타입을 사용하기 위해

import '../../../../core/error/failure.dart'; // Failure 클래스
import '../entities/restaurant_entity.dart'; // RestaurantEntity
import '../repositories/restaurant_repository.dart'; // RestaurantRepository 인터페이스

// Use Case의 기본 파라미터 타입을 정의하기 위한 추상 클래스 (선택 사항이지만 좋은 패턴)
// 모든 Use Case에 일관된 파라미터 전달 방식을 제공할 수 있습니다.
abstract class UseCaseParams {}

// GetNearbyRestaurantsUseCase를 위한 파라미터 클래스
class GetNearbyRestaurantsParams extends UseCaseParams {
  final double lat;
  final double lng;

  GetNearbyRestaurantsParams({required this.lat, required this.lng});
}

// Use Case의 기본 구조를 정의하는 추상 클래스 (선택 사항이지만 좋은 패턴)
// Type: Use Case의 성공 시 반환 타입
// Params: Use Case 실행에 필요한 파라미터 타입
abstract class UseCase<Type, Params extends UseCaseParams> {
  Future<Either<Failure, Type>> call(Params params);
}

// 주변 음식점 목록을 가져오는 Use Case
class GetNearbyRestaurantsUseCase
    implements UseCase<List<RestaurantEntity>, GetNearbyRestaurantsParams> {
  final RestaurantRepository repository;

  GetNearbyRestaurantsUseCase(this.repository);

  // Use Case를 실행하는 'call' 메서드
  // GetNearbyRestaurantsParams 객체를 파라미터로 받습니다.
  @override
  Future<Either<Failure, List<RestaurantEntity>>> call(
      GetNearbyRestaurantsParams params) async {
    // 주입받은 repository의 getNearbyRestaurants 메서드를 호출하고 결과를 반환합니다.
    return await repository.getNearbyRestaurants(params.lat, params.lng);
  }
}

/*
// 만약 UseCaseParams와 UseCase 추상 클래스를 사용하지 않고 더 간단하게 만들고 싶다면:
class GetNearbyRestaurantsUseCase {
  final RestaurantRepository repository;

  GetNearbyRestaurantsUseCase(this.repository);

  Future<Either<Failure, List<RestaurantEntity>>> call({
    required double lat,
    required double lng,
  }) async {
    return await repository.getNearbyRestaurants(lat, lng);
  }
}
*/

