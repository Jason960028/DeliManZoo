// lib/injection_container.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

// Core
import 'core/platform/network_info.dart';
import 'core/config/app_config.dart'; // AppConfig 사용 유지

// Features - Restaurant
import 'core/services/location_service.dart';
import 'features/restaurant/data/data_sources/restaurant_remote_data_source.dart';
import 'features/restaurant/data/repositories/restaurant_repository_impl.dart';
import 'features/restaurant/domain/repositories/restaurant_repository.dart';
import 'features/restaurant/domain/use_cases/get_nearby_restaurants_use_case.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // .env 파일에서 API 키 로드
  final googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
  if (googleMapsApiKey == null) {
    throw Exception("GOOGLE_MAPS_API_KEY not found in .env file");
  }
  print("DI Initialized with API Key from .env: $googleMapsApiKey");

  // AppConfig 등록 (API 키를 중앙에서 관리하고 다른 곳에서 참조하기 위함)
  sl.registerLazySingleton<AppConfig>(() => AppConfig(googleMapsApiKey: googleMapsApiKey));

  // External (http.Client 또는 Dio 등록)
  // http.Client를 사용한다고 가정
  sl.registerLazySingleton(() => http.Client());
  // 만약 Dio를 사용한다면:
  // sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => Connectivity());

  // Core Utilities
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<LocationService>(() => LocationService());

  // --- Features ---

  // Restaurant Feature
  // Data sources
  // RestaurantRemoteDataSource를 한 번만 올바르게 등록합니다.
  // RestaurantRemoteDataSourceImpl 생성자에 client와 apiKey가 필요하다고 가정합니다.
  sl.registerLazySingleton<RestaurantRemoteDataSource>(
        () => RestaurantRemoteDataSourceImpl(
      client: sl(), // http.Client 인스턴스를 주입
      // apiKey: googleMapsApiKey, // 직접 .env에서 읽은 키를 주입하거나, AppConfig를 통해 주입
      apiKey: sl<AppConfig>().googleMapsApiKey, // AppConfig를 통해 API 키 주입
    ),
  );

  // Repository
  sl.registerLazySingleton<RestaurantRepository>(
        () => RestaurantRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      // Repository에서도 AppConfig를 통해 API 키를 가져올 수 있습니다.
      // 만약 remoteDataSource가 이미 API 키를 가지고 있다면, Repository는 API 키를 직접 알 필요가 없을 수도 있습니다.
      // 현재 RestaurantRepositoryImpl이 apiKey를 직접 필요로 한다면 아래와 같이 유지합니다.
      apiKey: sl<AppConfig>().googleMapsApiKey,
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetNearbyRestaurantsUseCase(sl()));

  print('DI Initialized successfully. API Key from AppConfig: ${sl<AppConfig>().googleMapsApiKey}');
}


// API 키와 같은 설정을 위한 간단한 클래스 (선택 사항)
// lib/core/config/app_config.dart 파일로 분리하는 것이 좋음
class AppConfig {
  final String googleMapsApiKey;
  AppConfig({required this.googleMapsApiKey});
}

