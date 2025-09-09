import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/base_use_case.dart';
import '../../domain/use_cases/login_use_case.dart';
import '../../domain/use_cases/signup_use_case.dart';
import '../../domain/use_cases/google_sign_in_use_case.dart';
import '../../domain/use_cases/logout_use_case.dart';
import '../../domain/use_cases/get_current_user_use_case.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, UserEntity?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<UserEntity?> {
  late LoginUseCase _loginUseCase;
  late SignupUseCase _signupUseCase;
  late GoogleSignInUseCase _googleSignInUseCase;
  late LogoutUseCase _logoutUseCase;
  late GetCurrentUserUseCase _getCurrentUserUseCase;

  @override
  Future<UserEntity?> build() async {
    final authRepository = ref.read(authRepositoryProvider);

    _loginUseCase = LoginUseCase(authRepository);
    _signupUseCase = SignupUseCase(authRepository);
    _googleSignInUseCase = GoogleSignInUseCase(authRepository);
    _logoutUseCase = LogoutUseCase(authRepository);
    _getCurrentUserUseCase = GetCurrentUserUseCase(authRepository);

    // Listen to auth state changes
    final authStream = _getCurrentUserUseCase.call();

    // Convert stream to future for initial state
    try {
      return await authStream.first;
    } catch (e) {
      return null;
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final result = await _loginUseCase.call(
        LoginParams(email: email, password: password),
      );

      result.fold(
        (failure) {
          state = AsyncValue.error(failure, StackTrace.current);
        },
        (user) {
          state = AsyncValue.data(user);
        },
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final result = await _signupUseCase.call(
        SignupParams(email: email, password: password),
      );

      result.fold(
        (failure) {
          state = AsyncValue.error(failure, StackTrace.current);
        },
        (user) {
          state = AsyncValue.data(user);
        },
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final result = await _googleSignInUseCase.call(NoParams());

      result.fold(
        (failure) {
          state = AsyncValue.error(failure, StackTrace.current);
        },
        (user) {
          state = AsyncValue.data(user);
        },
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      final result = await _logoutUseCase.call(NoParams());

      result.fold(
        (failure) {
          state = AsyncValue.error(failure, StackTrace.current);
        },
        (success) {
          state = const AsyncValue.data(null);
        },
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  void listenToAuthChanges() {
    final authStream = _getCurrentUserUseCase.call();

    authStream.listen(
      (user) {
        if (state.hasValue) {
          state = AsyncValue.data(user);
        }
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }
}

// AuthRepository provider that should be overridden in main.dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
    "AuthRepositoryProvider must be overridden in ProviderScope.",
  );
});

// Convenience providers for checking auth state
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, _) => false,
  );
});

final currentUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, _) => null,
  );
});