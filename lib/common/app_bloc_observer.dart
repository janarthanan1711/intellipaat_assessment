import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/error/error_reporter.dart';

/// Reports any error thrown inside a bloc event handler.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    ErrorReporter.report(
      error,
      stackTrace,
      reason: 'Error in ${bloc.runtimeType}',
    );
    super.onError(bloc, error, stackTrace);
  }
}
