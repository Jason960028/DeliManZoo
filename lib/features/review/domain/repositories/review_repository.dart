import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/review_entity.dart';

abstract class ReviewRepository {
  Future<Either<Failure, List<ReviewEntity>>> getReviewsForPlace(String placeId);
  Future<Either<Failure, List<ReviewEntity>>> getUserReviews(String userId);
  Future<Either<Failure, ReviewEntity>> addReview(ReviewEntity review, List<File> imageFiles);
  Future<Either<Failure, ReviewEntity>> updateReview(ReviewEntity review, List<File>? newImageFiles);
  Future<Either<Failure, void>> deleteReview(String reviewId);
  Future<Either<Failure, ReviewEntity>> likeReview(String reviewId, String userId);
  Future<Either<Failure, ReviewEntity>> unlikeReview(String reviewId, String userId);
}