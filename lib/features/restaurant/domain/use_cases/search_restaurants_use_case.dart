import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/restaurant_entity.dart';
import '../repositories/restaurant_repository.dart';
import 'get_nearby_restaurants_use_case.dart'; // For UseCase

class SearchRestaurantsParams extends UseCaseParams {
  final String query;

  SearchRestaurantsParams({required this.query});
}

class SearchRestaurantsUseCase
    implements UseCase<List<RestaurantEntity>, SearchRestaurantsParams> {
  final RestaurantRepository repository;

  SearchRestaurantsUseCase(this.repository);

  @override
  Future<Either<Failure, List<RestaurantEntity>>> call(
      SearchRestaurantsParams params) async {
    return await repository.searchRestaurants(params.query);
  }
}
