// lib/injection_container.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Core
import 'core/platform/network_info.dart';

// Features - Restaurant
import 'core/services/location_service.dart';
import 'features/restaurant/data/data_sources/restaurant_remote_data_source.dart';
import 'features/restaurant/data/repositories/restaurant_repository_impl.dart';
import 'features/restaurant/domain/repositories/restaurant_repository.dart';
import 'features/restaurant/domain/use_cases/get_nearby_restaurants_use_case.dart';

// Features - Auth
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/use_cases/login_use_case.dart';
import 'features/auth/domain/use_cases/signup_use_case.dart';
import 'features/auth/domain/use_cases/google_sign_in_use_case.dart';
import 'features/auth/domain/use_cases/logout_use_case.dart';
import 'features/auth/domain/use_cases/get_current_user_use_case.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // .env 파일에서 API 키 로드
  final googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
  if (googleMapsApiKey == null) {
    throw Exception("GOOGLE_MAPS_API_KEY not found in .env file");
  }
  

  // AppConfig 등록 (API 키를 중앙에서 관리하고 다른 곳에서 참조하기 위함)
  sl.registerLazySingleton<AppConfig>(() => AppConfig(googleMapsApiKey: googleMapsApiKey));

  // External (http.Client 또는 Dio 등록)
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => Connectivity());

  // Firebase Auth and Google Sign-In
  sl.registerLazySingleton(() => FirebaseAuth.instance);

  // Google Sign-In v7.x: instance 사용, 설정은 AuthRepository에서 처리
  sl.registerLazySingleton(() => GoogleSignIn.instance);

  // Core Utilities
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<LocationService>(() => LocationService());

  // --- Features ---

  // Restaurant Feature
  // Data sources
  sl.registerLazySingleton<RestaurantRemoteDataSource>(
        () => RestaurantRemoteDataSourceImpl(
      client: sl(),
      apiKey: sl<AppConfig>().googleMapsApiKey,
    ),
  );

  // Repository
  sl.registerLazySingleton<RestaurantRepository>(
        () => RestaurantRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      apiKey: sl<AppConfig>().googleMapsApiKey,
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetNearbyRestaurantsUseCase(sl()));

  // Auth Feature
  // Repository
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      firebaseAuth: sl(),
      googleSignIn: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignupUseCase(sl()));
  sl.registerLazySingleton(() => GoogleSignInUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  
}

// API 키와 같은 설정을 위한 간단한 클래스
class AppConfig {
  final String googleMapsApiKey;
  AppConfig({required this.googleMapsApiKey});
}