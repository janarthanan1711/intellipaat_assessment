import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../../../core/error/error_reporter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/storage/session_storage.dart';
import '../../domain/model/login_response.dart';
import '../../domain/repository/auth_repository.dart';
import '../repository/auth_api.dart';

class AuthRepoImpl implements AuthRepository {
  AuthRepoImpl(this._api, this._sessionStorage, this._database);

  final AuthApi _api;
  final SessionStorage _sessionStorage;
  final AppDatabase _database;

  @override
  Future<Either<Failure, Unit>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.login(email: email, password: password);
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const FormatException('Login response is not an object');
      }
      await _sessionStorage.saveToken(LoginResponse.fromJson(body).token);
      return const Right(unit);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(
          UnauthorizedFailure(
            DioErrorHandler.serverMessage(e.response?.data) ??
                'Invalid email or password.',
          ),
        );
      }
      return Left(DioErrorHandler.toFailure(e));
    } on FormatException {
      return const Left(ParsingFailure());
    } on PlatformException catch (e, s) {
      ErrorReporter.report(e, s, reason: 'Saving auth token failed');
      return const Left(CacheFailure());
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      return await _sessionStorage.readToken() != null;
    } on PlatformException catch (e, s) {
      ErrorReporter.report(e, s, reason: 'Reading auth token failed');
      return false;
    }
  }

  @override
  Future<void> logout() async {
    await _sessionStorage.clear();
    await _database.clearAll();
  }
}
