import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repository/auth_repository.dart';

class AuthUsecase {
  const AuthUsecase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> login({
    required String email,
    required String password,
  }) => _repository.login(email: email.trim(), password: password);

  Future<bool> isLoggedIn() => _repository.isLoggedIn();

  Future<void> logout() => _repository.logout();
}
