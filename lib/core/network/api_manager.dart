import 'package:dio/dio.dart';

/// HTTP transport used by every feature API. Feature code depends on this
/// interface, never on how Dio is configured, so a fake can replace it in tests.
abstract interface class ApiManager {
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  });

  Future<Response<dynamic>> post(String path, {Object? data});
}
