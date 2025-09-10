import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/error/exceptions.dart';
import '../models/review_model.dart';
import '../../domain/entities/review_entity.dart';

abstract class ReviewRemoteDataSource {
  Future<List<ReviewModel>> getReviewsForPlace(String placeId);
  Future<List<ReviewModel>> getUserReviews(String userId);
  Future<ReviewModel> addReview(ReviewEntity review, List<File> imageFiles);
  Future<ReviewModel> updateReview(ReviewEntity review, List<File>? newImageFiles);
  Future<void> deleteReview(String reviewId);
  Future<ReviewModel> likeReview(String reviewId, String userId);
  Future<ReviewModel> unlikeReview(String reviewId, String userId);
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ReviewRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
  });


  @override
  Future<List<ReviewModel>> getReviewsForPlace(String placeId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot = await firestore
          .collection('reviews')
          .where('placeId', isEqualTo: placeId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get reviews for place: ${e.toString()}');
    }
  }

  @override
  Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get user reviews: ${e.toString()}');
    }
  }

  @override
  Future<ReviewModel> addReview(ReviewEntity review, List<File> imageFiles) async {
    try {
      final now = DateTime.now();
      
      // Upload images first
      final photoUrls = <String>[];
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final fileName = '${review.reviewId}_${i}_${now.millisecondsSinceEpoch}.jpg';
        final ref = storage.ref().child('review_photos/$fileName');
        
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        photoUrls.add(url);
      }

      // Create review with photo URLs
      final reviewModel = ReviewModel(
        reviewId: review.reviewId,
        userId: review.userId,
        placeId: review.placeId,
        rating: review.rating,
        comment: review.comment,
        photos: photoUrls,
        createdAt: now,
        updatedAt: now,
        userDisplayName: review.userDisplayName,
        userPhotoUrl: review.userPhotoUrl,
        likeCount: 0,
        likedByUserIds: const [],
      );

      // Add to Firestore
      await firestore
          .collection('reviews')
          .doc(review.reviewId)
          .set(reviewModel.toFirestore());

      // Also add to user's reviews subcollection for easy querying
      await firestore
          .collection('users')
          .doc(review.userId)
          .collection('reviews')
          .doc(review.reviewId)
          .set({
        'reviewId': review.reviewId,
        'placeId': review.placeId,
        'rating': review.rating,
        'createdAt': Timestamp.fromDate(now),
      });

      return reviewModel;
    } catch (e) {
      throw ServerException(message: 'Failed to add review: ${e.toString()}');
    }
  }

  @override
  Future<ReviewModel> updateReview(ReviewEntity review, List<File>? newImageFiles) async {
    try {
      final now = DateTime.now();
      List<String> photoUrls = List.from(review.photos);

      // Upload new images if provided
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        for (int i = 0; i < newImageFiles.length; i++) {
          final file = newImageFiles[i];
          final fileName = '${review.reviewId}_${photoUrls.length + i}_${now.millisecondsSinceEpoch}.jpg';
          final ref = storage.ref().child('review_photos/$fileName');
          
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          photoUrls.add(url);
        }
      }

      final updatedReview = ReviewModel(
        reviewId: review.reviewId,
        userId: review.userId,
        placeId: review.placeId,
        rating: review.rating,
        comment: review.comment,
        photos: photoUrls,
        createdAt: review.createdAt,
        updatedAt: now,
        userDisplayName: review.userDisplayName,
        userPhotoUrl: review.userPhotoUrl,
        likeCount: review.likeCount,
        likedByUserIds: review.likedByUserIds,
      );

      await firestore
          .collection('reviews')
          .doc(review.reviewId)
          .update(updatedReview.toFirestore());

      return updatedReview;
    } catch (e) {
      throw ServerException(message: 'Failed to update review: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      // Get the review first to get user info for deletion from user's subcollection
      final reviewDoc = await firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw ServerException(message: 'Review not found');
      }

      final reviewData = reviewDoc.data()!;
      final userId = reviewData['userId'] as String;
      final photos = List<String>.from(reviewData['photos'] ?? []);

      // Delete photos from storage
      for (final photoUrl in photos) {
        try {
          final ref = storage.refFromURL(photoUrl);
          await ref.delete();
        } catch (e) {
          // Continue even if photo deletion fails
        }
      }

      // Delete from main reviews collection
      await firestore.collection('reviews').doc(reviewId).delete();

      // Delete from user's reviews subcollection
      await firestore
          .collection('users')
          .doc(userId)
          .collection('reviews')
          .doc(reviewId)
          .delete();
    } catch (e) {
      throw ServerException(message: 'Failed to delete review: ${e.toString()}');
    }
  }

  @override
  Future<ReviewModel> likeReview(String reviewId, String userId) async {
    try {
      final reviewRef = firestore.collection('reviews').doc(reviewId);
      
      final result = await firestore.runTransaction((transaction) async {
        final reviewDoc = await transaction.get(reviewRef);
        if (!reviewDoc.exists) {
          throw ServerException(message: 'Review not found');
        }

        final reviewModel = ReviewModel.fromFirestore(reviewDoc);
        final likedByUserIds = List<String>.from(reviewModel.likedByUserIds);
        
        if (!likedByUserIds.contains(userId)) {
          likedByUserIds.add(userId);
          final updatedReview = reviewModel.copyWith(
            likeCount: reviewModel.likeCount + 1,
            likedByUserIds: likedByUserIds,
            updatedAt: DateTime.now(),
          );
          
          transaction.update(reviewRef, updatedReview.toFirestore());
          return updatedReview;
        }
        
        return reviewModel;
      });

      return result;
    } catch (e) {
      throw ServerException(message: 'Failed to like review: ${e.toString()}');
    }
  }

  @override
  Future<ReviewModel> unlikeReview(String reviewId, String userId) async {
    try {
      final reviewRef = firestore.collection('reviews').doc(reviewId);
      
      final result = await firestore.runTransaction((transaction) async {
        final reviewDoc = await transaction.get(reviewRef);
        if (!reviewDoc.exists) {
          throw ServerException(message: 'Review not found');
        }

        final reviewModel = ReviewModel.fromFirestore(reviewDoc);
        final likedByUserIds = List<String>.from(reviewModel.likedByUserIds);
        
        if (likedByUserIds.contains(userId)) {
          likedByUserIds.remove(userId);
          final updatedReview = reviewModel.copyWith(
            likeCount: reviewModel.likeCount - 1,
            likedByUserIds: likedByUserIds,
            updatedAt: DateTime.now(),
          );
          
          transaction.update(reviewRef, updatedReview.toFirestore());
          return updatedReview;
        }
        
        return reviewModel;
      });

      return result;
    } catch (e) {
      throw ServerException(message: 'Failed to unlike review: ${e.toString()}');
    }
  }
}