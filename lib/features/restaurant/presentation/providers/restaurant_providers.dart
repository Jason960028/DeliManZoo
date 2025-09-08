import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/restaurant_entity.dart';
import '../../domain/use_cases/get_nearby_restaurants_use_case.dart';
import '../../domain/repositories/restaurant_repository.dart'; // Repository 임포트 (UseCase 생성 시 필요)
// GetIt 인스턴스를 직접 사용하지 않으려면, Repository도 Riverpod Provider로 만들어 주입받을 수 있습니다.
// import '../../../core/di/injection_container.dart' as di; // GetIt 사용 시

// 1. RestaurantRepository 프로바이더 (선택 사항, GetIt 대신 Riverpod만 사용 시)
// 만약 GetIt(sl)을 사용하지 않고 Riverpod으로만 의존성 관리를 하고 싶다면,
// Repository도 Provider로 만들어야 합니다.
// 예시:
// final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
//   // 여기서 NetworkInfo, RestaurantRemoteDataSource 등을 ref.watch 또는 ref.read로 가져와서
//   // RestaurantRepositoryImpl 인스턴스를 생성하고 반환합니다.
//   // API 키도 안전하게 관리하여 주입해야 합니다.
//   // return di.sl<RestaurantRepository>(); // GetIt을 통해 가져오는 것도 하나의 방법
// });


// 2. GetNearbyRestaurantsUseCase 프로바이더 (선택 사항, Notifier 내부에서 직접 생성도 가능)
// UseCase 자체를 Provider로 만들어서 Notifier에 주입할 수도 있습니다.
final getNearbyRestaurantsUseCaseProvider = Provider<GetNearbyRestaurantsUseCase>((ref) {
  // final repository = ref.watch(restaurantRepositoryProvider); // 위에서 RepositoryProvider를 만들었다면
  // return GetNearbyRestaurantsUseCase(repository);

  // 만약 GetIt을 계속 사용한다면:
  // final repository = di.sl<RestaurantRepository>();
  // return GetNearbyRestaurantsUseCase(repository);

  // 이 예제에서는 AsyncNotifier 내부에서 UseCase를 직접 생성하겠습니다.
  // 실제로는 Repository를 Provider로 만들고, UseCase도 Provider로 만들어 주입하는 것이 더 깔끔할 수 있습니다.
  // 여기서는 간단하게 표현하기 위해 Notifier 내부에서 Repository를 가져와 UseCase를 생성합니다.
  // **주의:** 아래 RestaurantListNotifier에서는 GetIt(di.sl)을 사용하여 Repository를 가져옵니다.
  // Riverpod만 사용하려면 위 주석처럼 RepositoryProvider를 정의하고 사용해야 합니다.
  throw UnimplementedError("This provider is meant to be overridden or used with a concrete implementation strategy.");
});


// 3. 주변 음식점 목록을 관리하는 AsyncNotifierProvider
final restaurantListProvider =
AsyncNotifierProvider<RestaurantListNotifier, List<RestaurantEntity>>(() {
  return RestaurantListNotifier();
});

class RestaurantListNotifier extends AsyncNotifier<List<RestaurantEntity>> {
  // UseCase 인스턴스 (Notifier 내부에서 생성 또는 주입)
  late GetNearbyRestaurantsUseCase _getNearbyRestaurantsUseCase;

  // 초기 데이터를 로드하는 build 메서드
  // Provider가 처음 읽힐 때 또는 `ref.invalidateSelf()` 등으로 무효화될 때 호출됨
  @override
  Future<List<RestaurantEntity>> build() async {
    // Repository를 가져옵니다.
    // **방법 1: GetIt(di.sl) 사용 (기존 DI 컨테이너 활용)**
    // `main.dart`에서 `di.initDI()`가 먼저 호출되어야 합니다.
    // 이 방법은 Riverpod과 GetIt을 혼용하는 방식입니다.
    final restaurantRepository = ref.read(restaurantRepositoryProviderForRiverpod); // GetIt 인스턴스를 제공하는 Provider
    _getNearbyRestaurantsUseCase = GetNearbyRestaurantsUseCase(restaurantRepository);

    // **방법 2: Riverpod의 Provider로 Repository 주입 (Riverpod 스타일)**
    // final restaurantRepository = ref.watch(anotherRestaurantRepositoryProvider); // 별도의 Repository Provider
    // _getNearbyRestaurantsUseCase = GetNearbyRestaurantsUseCase(restaurantRepository);

    // 초기에는 특정 기본 위치로 데이터를 가져오거나, 빈 리스트를 반환할 수 있습니다.
    // 여기서는 예시로 서울 시청 근처를 기본 위치로 설정합니다.
    const double initialLat = 37.5665;
    const double initialLng = 126.9780;
    return _fetchRestaurants(initialLat, initialLng);
  }

  // 내부적으로 음식점 데이터를 가져오는 메서드
  Future<List<RestaurantEntity>> _fetchRestaurants(double lat, double lng) async {
    final result = await _getNearbyRestaurantsUseCase(
      GetNearbyRestaurantsParams(lat: lat, lng: lng),
    );

    return result.fold(
          (failure) {
        // 오류 발생 시 예외를 던져 AsyncValue.error 상태로 만듭니다.
        print("Error fetching restaurants in Notifier: ${failure.message}");
        throw failure; // 또는 구체적인 Exception 객체
      },
          (restaurants) {
        print("Fetched ${restaurants.length} restaurants in Notifier for $lat, $lng");
        return restaurants;
      },
    );
  }

  // 외부에서 호출하여 특정 위치의 음식점 데이터를 새로고침하는 메서드
  Future<void> fetchRestaurantsForLocation(double lat, double lng) async {
    // 현재 상태를 로딩 중으로 설정하고 새로운 데이터를 가져옵니다.
    state = const AsyncValue.loading();
    try {
      final restaurants = await _fetchRestaurants(lat, lng);
      state = AsyncValue.data(restaurants);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

// 필요하다면 다른 메서드 추가 (예: 필터링, 정렬 등)
}

// GetIt으로 생성된 RestaurantRepository를 Riverpod에서 사용하기 위한 Provider
// main.dart에서 GetIt 초기화(di.initDI())가 먼저 실행되어야 합니다.
// lib/injection_container.dart 에서 sl을 export 하거나, 여기서 직접 가져와야 합니다.
// 여기서는 injection_container.dart 파일에서 sl을 직접 참조한다고 가정합니다.
//
// **lib/injection_container.dart 에 다음을 추가:**
// final sl = GetIt.instance; // 이미 있다면 그대로 사용
// // ...
// RestaurantRepository get restaurantRepositoryInstance => sl<RestaurantRepository>();
//
// 또는, main.dart에서 di.sl을 넘겨받는 방식으로 Provider를 설정할 수도 있습니다.
// 여기서는 GetIt 인스턴스를 직접 참조하는 대신,
// main에서 GetIt 인스턴스를 받아 Provider를 override하는 방식을 권장합니다.
// 이 파일에서는 일단 GetIt을 직접 참조하지 않는 형태로 남겨두고,
// 사용하는 쪽(예: main.dart)에서 ProviderScope의 overrides를 통해 주입하도록 합니다.

// 임시 해결책: GetIt을 직접 참조 (권장하지 않음, ProviderScope overrides가 더 나은 방법)
// 만약 GetIt의 sl을 직접 사용하고 싶다면, 해당 파일을 import해야 합니다.
// import '../../../injection_container.dart' as di; // 경로 수정 필요

final restaurantRepositoryProviderForRiverpod = Provider<RestaurantRepository>((ref) {
  // **주의:** 이 방식은 GetIt과 Riverpod을 느슨하게 결합합니다.
  // 더 나은 방법은 main.dart의 ProviderScope의 overrides를 사용하거나,
  // 모든 의존성을 Riverpod으로 마이그레이션하는 것입니다.
  // return di.sl<RestaurantRepository>(); // GetIt 인스턴스를 사용하려면 di.sl을 활성화
  throw UnimplementedError(
      "RestaurantRepositoryProviderForRiverpod must be overridden in ProviderScope, "
          "or you should use GetIt directly (e.g., di.sl<RestaurantRepository>()) "
          "if you are mixing GetIt and Riverpod."
  );
});

