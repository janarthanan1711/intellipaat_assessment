import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app.dart';
import 'common/app_bloc_observer.dart';
import 'common/app_routes.dart';
import 'core/di/injection.dart' as di;
import 'core/error/error_reporter.dart';
import 'features/auth/domain/usecases/auth_usecase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    ErrorReporter.report(
      details.exception,
      details.stack,
      reason: 'Flutter error',
    );
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    ErrorReporter.report(error, stack, reason: 'Uncaught async error');
    return true;
  };

  await di.init();
  Bloc.observer = const AppBlocObserver();

  final loggedIn = await di.serviceLocator<AuthUsecase>().isLoggedIn();
  runApp(
    LearningDashboardApp(
      initialRoute: loggedIn ? AppRoutes.dashboard : AppRoutes.login,
    ),
  );
}
