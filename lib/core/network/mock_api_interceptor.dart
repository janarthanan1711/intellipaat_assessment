import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../common/app_constants.dart';
import 'endpoints.dart';

/// Stands in for the backend: answers requests from `assets/mock/` after a
/// simulated latency. When the device has no connectivity it fails exactly
/// like a real request would (`DioExceptionType.connectionError`), so the
/// app's offline path is the production one.
///
/// The mock server is stateless — lesson completions are not persisted
/// server-side, which is what makes local-first merging observable.
class MockApiInterceptor extends Interceptor {
  MockApiInterceptor({
    required Connectivity connectivity,
    AssetBundle? bundle,
    this.latency = const Duration(milliseconds: 700),
    this.scenario = AppConstants.mockScenario,
  }) : _connectivity = connectivity,
       _bundle = bundle ?? rootBundle;

  final Connectivity _connectivity;
  final AssetBundle _bundle;
  final Duration latency;
  final String scenario;

  static final _lessonsPath = RegExp(r'^/courses/(\d+)/lessons$');
  static final _completePath = RegExp(r'^/lessons/(\d+)/complete$');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await Future<void>.delayed(latency);

    if (await _isOffline()) {
      handler.reject(
        DioException.connectionError(
          requestOptions: options,
          reason: 'No network connectivity',
        ),
        true,
      );
      return;
    }

    try {
      final response = await _route(options);
      final statusCode = response.statusCode ?? 500;
      if (statusCode >= 400) {
        handler.reject(
          DioException.badResponse(
            statusCode: statusCode,
            requestOptions: options,
            response: response,
          ),
          true,
        );
      } else {
        handler.resolve(response, true);
      }
    } catch (e, s) {
      handler.reject(
        DioException(requestOptions: options, error: e, stackTrace: s),
        true,
      );
    }
  }

  Future<bool> _isOffline() async {
    final results = await _connectivity.checkConnectivity();
    return results.every((r) => r == ConnectivityResult.none);
  }

  Future<Response<dynamic>> _route(RequestOptions options) async {
    final method = options.method.toUpperCase();
    final path = options.path;

    if (method == 'POST' && path == ApiEndpoints.login) {
      return _login(options);
    }
    if (scenario == 'error') {
      return _json(options, 500, {'message': 'The server is unavailable.'});
    }
    if (method == 'GET' && path == ApiEndpoints.courses) {
      if (scenario == 'empty') return _json(options, 200, <Object>[]);
      return _json(options, 200, await _asset('courses.json'));
    }

    final lessonsMatch = _lessonsPath.firstMatch(path);
    if (method == 'GET' && lessonsMatch != null) {
      final lessonsByCourse = await _asset('lessons.json');
      final lessons = lessonsByCourse is Map<String, dynamic>
          ? lessonsByCourse[lessonsMatch.group(1)]
          : null;
      return lessons == null
          ? _json(options, 404, {'message': 'Course not found.'})
          : _json(options, 200, lessons);
    }

    if (method == 'POST' && _completePath.hasMatch(path)) {
      return _json(options, 200, {'success': true});
    }

    return _json(options, 404, {'message': 'Not found: $method $path'});
  }

  Response<dynamic> _login(RequestOptions options) {
    final valid = switch (options.data) {
      {'email': final String email, 'password': final String password} =>
        email.trim().toLowerCase() == AppConstants.demoEmail &&
            password == AppConstants.demoPassword,
      _ => false,
    };
    if (!valid) {
      return _json(options, 401, {'message': 'Invalid email or password.'});
    }
    return _json(options, 200, {
      'token': 'mock-token-${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  Future<Object?> _asset(String name) async =>
      jsonDecode(await _bundle.loadString('assets/mock/$name'));

  Response<dynamic> _json(
    RequestOptions options,
    int statusCode,
    Object? data,
  ) => Response<dynamic>(
    requestOptions: options,
    statusCode: statusCode,
    data: data,
  );
}
