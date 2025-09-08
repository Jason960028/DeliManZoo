import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';

abstract class UseCaseParams {}

class NoParams extends UseCaseParams {}

abstract class UseCase<Type, Params extends UseCaseParams> {
  Future<Either<Failure, Type>> call(Params params);
}