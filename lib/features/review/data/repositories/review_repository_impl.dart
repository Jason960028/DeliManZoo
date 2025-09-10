import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/platform/network_info.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';
import '../data_sources/review_remote_data_source.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ReviewRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ReviewEntity>>> getReviewsForPlace(String placeId) async {
    if (await networkInfo.isConnected) {
      try {
        final reviews = await remoteDataSource.getReviewsForPlace(placeId);
        return Right(reviews);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Failed to get reviews: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<ReviewEntity>>> getUserReviews(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final reviews = await remoteDataSource.getUserReviews(userId);
        return Right(reviews);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Failed to get user reviews: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ReviewEntity>> addReview(ReviewEntity review, List<File> imageFiles) async {
    if (await networkInfo.isConnected) {
      try {
        final addedReview = await remoteDataSource.addReview(review, imageFiles);
        return Right(addedReview);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Failed to add review: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ReviewEntity>> updateReview(ReviewEntity review, List<File>? newImageFiles) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedReview = await remoteDataSource.updateReview(review, newImageFiles);
        return Right(updatedReview);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Failed to update review: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReview(String reviewId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteReview(reviewId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Failed to delete review: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ReviewEntity>> likeReview(String reviewId, String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final likedReview = await remoteDataSource.likeReview(reviewId, userId);
        return Right(likedReview);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Failed to like review: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ReviewEntity>> unlikeReview(String reviewId, String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final unlikedReview = await remoteDataSource.unlikeReview(reviewId, userId);
        return Right(unlikedReview);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Failed to unlike review: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}