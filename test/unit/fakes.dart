import 'package:dartz/dartz.dart';
import 'package:learning_dashboard/core/error/failures.dart';
import 'package:learning_dashboard/features/auth/domain/usecases/auth_usecase.dart';

class FakeAuthUsecase implements AuthUsecase {
  FakeAuthUsecase(this.result);

  final Either<Failure, Unit> result;
  int loginCalls = 0;

  @override
  Future<Either<Failure, Unit>> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    return result;
  }

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<void> logout() async {}
}
