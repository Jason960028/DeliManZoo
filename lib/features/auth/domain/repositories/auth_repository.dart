import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';
abstract class AuthRepository {
  /// Returns a stream of the current authentication state.
  /// Returns a stream containing [UserEntity] when logged in, null when logged out.
  Stream<UserEntity?> get authStateChanges;

  /// Creates a new account with email and password.
  ///
  /// Returns Right with [UserEntity] on success.
  /// Returns Left with [Failure] on failure.
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Signs in with email and password.
  ///
  /// Returns Right with [UserEntity] on success.
  /// Returns Left with [Failure] on failure.
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Signs in with Google account.
  ///
  /// Returns Right with [UserEntity] on success.
  /// Returns Left with [Failure] on failure.
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Signs out the current user.
  ///
  /// Returns Right with [Unit] on success.
  /// Returns Left with [Failure] on failure.
  Future<Either<Failure, Unit>> signOut();

  /// Updates user profile information.
  ///
  /// Returns Right with updated [UserEntity] on success.
  /// Returns Left with [Failure] on failure.
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? photoURL,
  });
}
