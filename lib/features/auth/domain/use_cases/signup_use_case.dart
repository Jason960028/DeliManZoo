import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import 'base_use_case.dart';

class SignupParams extends UseCaseParams {
  final String email;
  final String password;

  SignupParams({
    required this.email,
    required this.password,
  });
}

class SignupUseCase implements UseCase<UserEntity, SignupParams> {
  final AuthRepository repository;

  SignupUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignupParams params) async {
    return await repository.signUpWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}