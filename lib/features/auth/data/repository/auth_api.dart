import 'package:dio/dio.dart';

import '../../../../core/network/network.dart';

/// Transport only: builds requests, returns raw responses.
class AuthApi {
  const AuthApi(this._apiManager);

  final ApiManager _apiManager;

  Future<Response<dynamic>> login({
    required String email,
    required String password,
  }) => _apiManager.post(
    ApiEndpoints.login,
    data: {'email': email, 'password': password},
  );
}
