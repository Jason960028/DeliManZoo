import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/platform/network_info.dart'; // NetworkInfo 임포트
import '../../domain/entities/restaurant_entity.dart';
import '../../domain/repositories/restaurant_repository.dart';
import '../data_sources/restaurant_remote_data_source.dart';
// RestaurantModel은 RestaurantEntity를 상속하므로, 모델 자체를 엔티티로 취급할 수 있습니다.
// 만약 모델과 엔티티 간의 명시적인 변환이 필요하다면, 여기서 변환 로직을 추가합니다.

class RestaurantRepositoryImpl implements RestaurantRepository {
  final RestaurantRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo; // 네트워크 정보 인터페이스 주입
  final String apiKey; // API 키 주입

  RestaurantRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.apiKey, // 생성자를 통해 API 키를 받음
  });

  @override
  Future<Either<Failure, List<RestaurantEntity>>> getNearbyRestaurants(
      double lat, double lng) async {
    if (await networkInfo.isConnected) {
      try {
        // RestaurantRemoteDataSource는 이미 List<RestaurantModel>을 반환합니다.
        // RestaurantModel은 RestaurantEntity를 상속하므로, 그대로 사용하거나
        // 필요에 따라 명시적으로 엔티티로 변환할 수 있습니다.
        // 여기서는 RestaurantModel이 RestaurantEntity와 호환된다고 가정합니다.
        final remoteRestaurants =
        await remoteDataSource.getNearbyRestaurants(lat, lng, apiKey);

        // 만약 RestaurantModel과 RestaurantEntity가 필드가 다르거나 추가적인 변환이 필요하다면:
        // final List<RestaurantEntity> restaurantEntities = remoteRestaurants.map((model) => model.toEntity()).toList();
        // return Right(restaurantEntities);

        // RestaurantModel이 RestaurantEntity의 모든 필드를 포함하고 Equatable을 올바르게 구현했다면
        // 다음과 같이 바로 반환할 수 있습니다.
        return Right(remoteRestaurants);
      } on ServerException catch (e) {
        // API에서 명시적으로 발생시킨 오류 (예: 잘못된 요청, API 키 오류 등)
        return Left(ServerFailure(message: e.message, properties: [e.statusCode ?? 'N/A']));
      } catch (e) {
        // 그 외 예기치 않은 오류 (예: 데이터 파싱 오류가 remoteDataSource에서 ServerException으로 변환되지 않은 경우)
        // 실제로는 remoteDataSource에서 ServerException으로 잘 변환해 줄 것이므로, 이 catch 블록은 더 일반적인 오류를 위한 것
        return Left(ServerFailure(message: '알 수 없는 서버 오류가 발생했습니다: ${e.toString()}'));
      }
    } else {
      // 네트워크 연결이 없는 경우
      return Left(NetworkFailure(message: '인터넷에 연결되어 있지 않습니다.'));
    }
  }
}


