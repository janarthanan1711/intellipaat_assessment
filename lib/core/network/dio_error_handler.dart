import 'dart:io';

import 'package:dio/dio.dart';

import '../error/failures.dart';

abstract final class DioErrorHandler {
  /// True when the request never got a response because of connectivity.
  static bool isNetworkError(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    _ => e.error is SocketException,
  };

  static Failure toFailure(DioException e) {
    if (isNetworkError(e)) return const NetworkFailure();

    final response = e.response;
    if (e.type == DioExceptionType.badResponse && response != null) {
      final statusCode = response.statusCode;
      final message = serverMessage(response.data);
      if (statusCode == 401) {
        return message == null
            ? const UnauthorizedFailure()
            : UnauthorizedFailure(message);
      }
      return ServerFailure(
        message ?? 'Server error ($statusCode). Please try again.',
        statusCode: statusCode,
      );
    }
    return const UnexpectedFailure();
  }

  /// Extracts `{"message": "..."}` from an error body, if present.
  static String? serverMessage(Object? body) => switch (body) {
    {'message': final String message} => message,
    _ => null,
  };
}
