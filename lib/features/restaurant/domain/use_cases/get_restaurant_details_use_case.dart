import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/restaurant_entity.dart';
import '../repositories/restaurant_repository.dart';

class GetRestaurantDetailsUseCase {
  final RestaurantRepository repository;

  GetRestaurantDetailsUseCase(this.repository);

  Future<Either<Failure, RestaurantEntity>> call(String placeId) async {
    return await repository.getRestaurantDetails(placeId);
  }
}