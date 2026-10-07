import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, Unit>> login({
    required String email,
    required String password,
  });

  Future<bool> isLoggedIn();

  /// Ends the session and removes this user's cached data from the device.
  Future<void> logout();
}
