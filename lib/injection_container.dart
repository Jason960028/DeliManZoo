// lib/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

// Core
import 'core/platform/network_info.dart'; // 실제 경로로 수정
import 'core/config/app_config.dart'; // API 키 관리를 위한 클래스 (선택 사항)


// Features - Restaurant
import 'features/restaurant/data/data_sources/restaurant_remote_data_source.dart'; // 실제 경로로 수정
import 'features/restaurant/data/repositories/restaurant_repository_impl.dart'; // 실제 경로로 수정
import 'features/restaurant/domain/repositories/restaurant_repository.dart'; // 실제 경로로 수정
// Use cases (필요하다면 나중에 추가)
// import 'features/restaurant/domain/usecases/get_nearby_restaurants_usecase.dart'; // 실제 경로로 수정

// Blocs / Cubits (필요하다면 나중에 추가)
// import 'features/restaurant/presentation/bloc/restaurant_bloc.dart'; // 실제 경로로 수정
import 'features/restaurant/domain/use_cases/get_nearby_restaurants_use_case.dart'; // UseCase 임포트

final sl = GetIt.instance; // Service Locator

Future<void> initDI() async {
  // --- Core ---
  // API 키 (안전하게 로드하는 방법으로 수정 필요)
  // 예시: AppConfig 클래스를 통해 환경 변수 또는 다른 방식으로 로드
  // 여기서는 직접 문자열로 넣지만, 실제 앱에서는 절대 이렇게 하지 마세요.
  const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'YOUR_DEFAULT_API_KEY_IF_NOT_SET', // 빌드 시 전달되지 않았을 경우의 기본값
  );
  sl.registerLazySingleton<AppConfig>(() => AppConfig(googleMapsApiKey: googleMapsApiKey));


  // External
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => Connectivity());

  // Core Utilities
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // --- Features ---

  // Restaurant Feature
  // Data sources
  sl.registerLazySingleton<RestaurantRemoteDataSource>(
        () => RestaurantRemoteDataSourceImpl(client: sl()),
  );

  // Repository
  sl.registerLazySingleton<RestaurantRepository>(
        () => RestaurantRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      apiKey: sl<AppConfig>().googleMapsApiKey, // AppConfig에서 API 키 가져오기
    ),
  );

  // Use cases (주석 처리된 부분은 나중에 필요시 활성화)
  sl.registerLazySingleton(() => GetNearbyRestaurantsUseCase(sl())); // Repository(sl())를 주입

  // Blocs / Cubits (주석 처리된 부분은 나중에 필요시 활성화)
  // 예시: sl.registerFactory(() => RestaurantBloc(getNearbyRestaurantsUseCase: sl()));

  print('DI Initialized with API Key: ${sl<AppConfig>().googleMapsApiKey}'); // API 키 로드 확인용
}

// API 키와 같은 설정을 위한 간단한 클래스 (선택 사항)
// lib/core/config/app_config.dart 파일로 분리하는 것이 좋음
class AppConfig {
  final String googleMapsApiKey;
  AppConfig({required this.googleMapsApiKey});
}

