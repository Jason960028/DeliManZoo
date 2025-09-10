import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/use_cases/add_review_use_case.dart';
import '../../domain/use_cases/get_reviews_for_place_use_case.dart';
import '../../domain/use_cases/like_review_use_case.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  throw UnimplementedError('ReviewRepository provider must be overridden');
});

final getReviewsForPlaceUseCaseProvider = Provider<GetReviewsForPlaceUseCase>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return GetReviewsForPlaceUseCase(repository);
});

final addReviewUseCaseProvider = Provider<AddReviewUseCase>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return AddReviewUseCase(repository);
});

final likeReviewUseCaseProvider = Provider<LikeReviewUseCase>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return LikeReviewUseCase(repository);
});

final unlikeReviewUseCaseProvider = Provider<UnlikeReviewUseCase>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return UnlikeReviewUseCase(repository);
});

final reviewsForPlaceProvider = StateNotifierProvider.family<ReviewsNotifier, AsyncValue<List<ReviewEntity>>, String>((ref, placeId) {
  final useCase = ref.watch(getReviewsForPlaceUseCaseProvider);
  return ReviewsNotifier(useCase, placeId);
});

final userReviewsProvider = StateNotifierProvider<UserReviewsNotifier, AsyncValue<List<ReviewEntity>>>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  return UserReviewsNotifier(repository, currentUser);
});

class ReviewsNotifier extends StateNotifier<AsyncValue<List<ReviewEntity>>> {
  final GetReviewsForPlaceUseCase _getReviewsUseCase;
  final String placeId;

  ReviewsNotifier(this._getReviewsUseCase, this.placeId) : super(const AsyncValue.loading()) {
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    state = const AsyncValue.loading();
    final result = await _getReviewsUseCase(placeId);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (reviews) => state = AsyncValue.data(reviews),
    );
  }

  void addReview(ReviewEntity review) {
    state.whenData((reviews) {
      state = AsyncValue.data([review, ...reviews]);
    });
  }

  void updateReview(ReviewEntity updatedReview) {
    state.whenData((reviews) {
      final updatedReviews = reviews.map((review) {
        if (review.reviewId == updatedReview.reviewId) {
          return updatedReview;
        }
        return review;
      }).toList();
      state = AsyncValue.data(updatedReviews);
    });
  }

  void removeReview(String reviewId) {
    state.whenData((reviews) {
      final filteredReviews = reviews.where((review) => review.reviewId != reviewId).toList();
      state = AsyncValue.data(filteredReviews);
    });
  }
}

class UserReviewsNotifier extends StateNotifier<AsyncValue<List<ReviewEntity>>> {
  final ReviewRepository _repository;
  final dynamic _currentUser;

  UserReviewsNotifier(this._repository, this._currentUser) : super(const AsyncValue.loading()) {
    if (_currentUser != null) {
      fetchUserReviews();
    }
  }

  Future<void> fetchUserReviews() async {
    if (_currentUser == null) return;
    
    state = const AsyncValue.loading();
    final result = await _repository.getUserReviews(_currentUser.uid);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (reviews) => state = AsyncValue.data(reviews),
    );
  }
}

class AddReviewNotifier extends StateNotifier<AsyncValue<void>> {
  final AddReviewUseCase _addReviewUseCase;

  AddReviewNotifier(this._addReviewUseCase) : super(const AsyncValue.data(null));

  Future<void> addReview(ReviewEntity review, List<File> imageFiles) async {
    state = const AsyncValue.loading();
    
    final params = AddReviewParams(
      review: review,
      imageFiles: imageFiles,
    );
    
    final result = await _addReviewUseCase(params);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (review) => state = const AsyncValue.data(null),
    );
  }
}

final addReviewNotifierProvider = StateNotifierProvider<AddReviewNotifier, AsyncValue<void>>((ref) {
  final useCase = ref.watch(addReviewUseCaseProvider);
  return AddReviewNotifier(useCase);
});