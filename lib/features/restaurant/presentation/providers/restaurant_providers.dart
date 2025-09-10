import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/restaurant_entity.dart';
import '../../../../core/error/failure.dart'; // Failure 및 하위 클래스들 임포트
import '../../../../core/services/location_service.dart';
import '../../domain/use_cases/get_nearby_restaurants_use_case.dart';
import '../../domain/use_cases/search_restaurants_use_case.dart';
import '../../domain/repositories/restaurant_repository.dart';

// ... (getNearbyRestaurantsUseCaseProvider 주석은 그대로 두거나 필요에 따라 사용) ...
// final getNearbyRestaurantsUseCaseProvider = Provider<GetNearbyRestaurantsUseCase>((ref) {
//   throw UnimplementedError("This provider is meant to be overridden or used with a concrete implementation strategy.");
// });

final restaurantListProvider =
AsyncNotifierProvider<RestaurantListNotifier, List<RestaurantEntity>>(() {
  return RestaurantListNotifier();
});

class RestaurantListNotifier extends AsyncNotifier<List<RestaurantEntity>> {
  late GetNearbyRestaurantsUseCase _getNearbyRestaurantsUseCase;
  late SearchRestaurantsUseCase _searchRestaurantsUseCase;
  late LocationService _locationService;

  @override
  Future<List<RestaurantEntity>> build() async {
    final restaurantRepository = ref.read(restaurantRepositoryProviderForRiverpod);
    _getNearbyRestaurantsUseCase = GetNearbyRestaurantsUseCase(restaurantRepository);
    _searchRestaurantsUseCase = SearchRestaurantsUseCase(restaurantRepository);
    _locationService = ref.read(locationServiceProvider); // LocationService 프로바이더를 통해 가져오기

    try {
      
      final position = await _locationService.getCurrentPosition();
      
      return _fetchRestaurants(position.latitude, position.longitude);
    } catch (e) {
      
      if (e is String) {
        // LocationService에서 String으로 오류 메시지를 반환하는 경우
        if (e.contains('위치 권한') || e.contains('위치 서비스')) {
          throw LocationFailure(message: e); // <<< 수정: LocationFailure 사용
        }
      }
      // 그 외 일반적인 오류는 ServerFailure로 처리 (또는 다른 적절한 Failure)
      throw ServerFailure(
          message:
          "현재 위치를 가져오는데 실패했습니다: ${e.toString()}"); // <<< 수정: ServerFailure 사용
    }
  }

  Future<List<RestaurantEntity>> _fetchRestaurants(
      double lat, double lng) async {
    final result = await _getNearbyRestaurantsUseCase(
      GetNearbyRestaurantsParams(lat: lat, lng: lng),
    );
    return result.fold(
          (failure) {
        
        throw failure; // 여기는 이미 구체적인 Failure 객체가 넘어올 것으로 예상
      },
          (restaurants) {
        
        return restaurants;
      },
    );
  }

  Future<void> fetchRestaurantsForLocation(double lat, double lng) async {
    print('🔍 [DEBUG] fetchRestaurantsForLocation called with lat: $lat, lng: $lng');
    state = const AsyncValue.loading();
    try {
      final restaurants = await _fetchRestaurants(lat, lng);
      print('🔍 [DEBUG] Successfully fetched ${restaurants.length} restaurants');
      state = AsyncValue.data(restaurants);
    } catch (e, s) {
      print('🔍 [DEBUG] Error fetching restaurants: $e');
      // _fetchRestaurants에서 이미 구체적인 Failure를 throw하므로, 그대로 사용
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> fetchRestaurantsForCurrentLocation() async {
    state = const AsyncValue.loading();
    try {
      
      final position = await _locationService.getCurrentPosition();
      
      final restaurants =
      await _fetchRestaurants(position.latitude, position.longitude);
      state = AsyncValue.data(restaurants);
    } catch (e, s) {
      
      if (e is String) {
        // LocationService에서 String으로 오류 메시지를 반환하는 경우
        if (e.contains('위치 권한') || e.contains('위치 서비스')) {
          state = AsyncValue.error(
              LocationFailure(message: e), s); // <<< 수정: LocationFailure 사용
          return;
        }
      }
      // 그 외 일반적인 오류 처리
      state = AsyncValue.error(
          ServerFailure(
              message: "현재 위치를 사용한 새로고침에 실패했습니다: ${e.toString()}"), // <<< 수정: ServerFailure 사용
          s);
    }
  }

  Future<void> searchRestaurants(String query) async {
    state = const AsyncValue.loading();
    final result = await _searchRestaurantsUseCase(SearchRestaurantsParams(query: query));
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (restaurants) => state = AsyncValue.data(restaurants),
    );
  }
}

// LocationService를 위한 Provider
final locationServiceProvider = Provider<LocationService>((ref) {
  // LocationService는 다른 의존성이 없으므로 직접 생성 가능
  return LocationService();
  // 또는 GetIt을 사용한다면:
  // import '../../../injection_container.dart' as di;
  // return di.sl<LocationService>();
  // 이 경우, main.dart의 ProviderScope overrides에 di.sl<LocationService>()를 주입하는 것이
  // Riverpod 패턴에 더 부합할 수 있습니다.
});

// GetIt으로 생성된 RestaurantRepository를 Riverpod에서 사용하기 위한 Provider
final restaurantRepositoryProviderForRiverpod =
Provider<RestaurantRepository>((ref) {
  // 이 Provider는 main.dart의 ProviderScope의 overrides를 통해 실제 값을 주입받아야 합니다.
  throw UnimplementedError(
      "RestaurantRepositoryProviderForRiverpod must be overridden in ProviderScope.");
});

