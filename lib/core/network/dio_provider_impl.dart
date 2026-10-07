import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../common/app_constants.dart';
import 'api_manager.dart';

/// The only place Dio is configured.
class DioProviderImpl implements ApiManager {
  /// [interceptors] run in order; transport-level ones (such as the mock
  /// server) go last so auth headers are already attached.
  DioProviderImpl({List<Interceptor> interceptors = const []})
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: AppConstants.networkTimeout,
          sendTimeout: AppConstants.networkTimeout,
          receiveTimeout: AppConstants.networkTimeout,
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      ) {
    _dio.interceptors.addAll([
      if (kDebugMode) _DebugLogInterceptor(),
      ...interceptors,
    ]);
  }

  final Dio _dio;

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _dio.get<dynamic>(path, queryParameters: queryParameters);

  @override
  Future<Response<dynamic>> post(String path, {Object? data}) =>
      _dio.post<dynamic>(path, data: data);
}

/// Logs method, path and status only — never headers or bodies, which carry
/// tokens and credentials.
class _DebugLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log('--> ${options.method} ${options.path}', name: 'HTTP');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final request = response.requestOptions;
    developer.log(
      '<-- ${response.statusCode} ${request.method} ${request.path}',
      name: 'HTTP',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = err.requestOptions;
    developer.log(
      '<-- ${err.response?.statusCode ?? err.type.name} '
      '${request.method} ${request.path}',
      name: 'HTTP',
    );
    handler.next(err);
  }
}
