import 'package:dio/dio.dart';

import '../error/error_reporter.dart';
import '../storage/session_storage.dart';

/// Attaches the bearer token and ends the session on a genuine 401.
///
/// Network failures (timeouts, no connectivity) pass through untouched: being
/// offline must never log the user out.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SessionStorage sessionStorage,
    required Future<void> Function() onUnauthorized,
  }) : _sessionStorage = sessionStorage,
       _onUnauthorized = onUnauthorized;

  static const _authHeader = 'Authorization';

  final SessionStorage _sessionStorage;
  final Future<void> Function() _onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _sessionStorage.readToken();
      if (token != null) options.headers[_authHeader] = 'Bearer $token';
    } catch (e, s) {
      // A keystore read failure shouldn't block the request; the server will
      // answer 401 if auth was actually required.
      ErrorReporter.report(e, s, reason: 'Reading auth token failed');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only requests that carried a token can have an expired session; a 401
    // on login just means wrong credentials.
    final wasAuthenticated = err.requestOptions.headers.containsKey(
      _authHeader,
    );
    if (err.response?.statusCode == 401 && wasAuthenticated) {
      await _onUnauthorized();
    }
    handler.next(err);
  }
}
