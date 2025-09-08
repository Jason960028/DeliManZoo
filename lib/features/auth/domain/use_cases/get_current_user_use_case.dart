import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import 'base_use_case.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Stream<UserEntity?> call() {
    return repository.authStateChanges;
  }
}