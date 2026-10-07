import 'dart:developer' as developer;

/// Single seam for error reporting. In production this forwards to
/// Crashlytics/Sentry; here it logs so the call sites are already in place.
abstract final class ErrorReporter {
  static void report(Object error, StackTrace? stackTrace, {String? reason}) {
    developer.log(
      reason ?? 'Unhandled error',
      name: 'ErrorReporter',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
