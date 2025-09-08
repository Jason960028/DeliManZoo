import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user != null) {
        return UserModel.fromFirebaseUser(user);
      }
      return null;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userModel = UserModel.fromFirebaseUser(userCredential.user!);
        return Right(userModel);
      } else {
        return const Left(AuthFailure(message: 'Failed to create account.'));
      }
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure(message: 'Unknown error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userModel = UserModel.fromFirebaseUser(userCredential.user!);
        return Right(userModel);
      } else {
        return const Left(AuthFailure(message: 'Failed to sign in.'));
      }
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure(message: 'Unknown error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      // Use latest google_sign_in API
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) {
        return const Left(AuthFailure(message: 'Google sign-in was cancelled.'));
      }

      // In google_sign_in v7, authentication is synchronous
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Get access token through authorization client
      final authClient = _googleSignIn.authorizationClient;
      final authorization = await authClient.authorizationForScopes(['email']);
      
      if (authorization?.accessToken == null || googleAuth.idToken == null) {
        return const Left(AuthFailure(message: 'Failed to get Google authentication tokens.'));
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: authorization!.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final userModel = UserModel.fromFirebaseUser(userCredential.user!);
        return Right(userModel);
      } else {
        return const Left(AuthFailure(message: 'Google sign-in failed.'));
      }
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure(message: 'Error occurred during Google sign-in: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(), // Use signOut() instead of disconnect()
      ]);
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(message: 'Error occurred during sign out: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return const Left(AuthFailure(message: 'No user is currently signed in.'));
      }

      await currentUser.updateDisplayName(displayName);
      if (photoURL != null) {
        await currentUser.updatePhotoURL(photoURL);
      }

      await currentUser.reload();
      final updatedUser = _firebaseAuth.currentUser;

      if (updatedUser != null) {
        final userModel = UserModel.fromFirebaseUser(updatedUser);
        return Right(userModel);
      } else {
        return const Left(AuthFailure(message: 'Failed to update profile.'));
      }
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure(message: 'Error occurred during profile update: ${e.toString()}'));
    }
  }

  Failure _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return const AuthFailure(message: 'Password is too weak.');
      case 'email-already-in-use':
        return const AuthFailure(message: 'Email is already in use.');
      case 'user-not-found':
        return const AuthFailure(message: 'User not found.');
      case 'wrong-password':
        return const AuthFailure(message: 'Wrong password.');
      case 'invalid-email':
        return const AuthFailure(message: 'Invalid email format.');
      case 'user-disabled':
        return const AuthFailure(message: 'User account has been disabled.');
      case 'too-many-requests':
        return const AuthFailure(message: 'Too many requests. Please try again later.');
      case 'operation-not-allowed':
        return const AuthFailure(message: 'Operation not allowed.');
      default:
        return AuthFailure(message: 'Firebase Auth error: ${e.message ?? e.code}');
    }
  }
}


class AuthFailure extends Failure {
  const AuthFailure({required String message, List<dynamic> properties = const []})
      : super(message: message, properties: properties);
}