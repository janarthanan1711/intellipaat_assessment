import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injection.dart';
import '../core/error/error_page.dart';
import '../features/auth/application/login_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/courses/application/course_detail_bloc.dart';
import '../features/courses/application/dashboard_bloc.dart';
import '../features/courses/presentation/pages/course_detail_page.dart';
import '../features/courses/presentation/pages/dashboard_page.dart';
import 'app_arguments.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const courseDetail = '/course-detail';

  /// Each route gets a fresh bloc from the service locator, scoped to the page.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      login => BlocProvider(
        create: (_) => serviceLocator<LoginBloc>(),
        child: const LoginPage(),
      ),
      dashboard => BlocProvider(
        create: (_) =>
            serviceLocator<DashboardBloc>()..add(const DashboardStarted()),
        child: const DashboardPage(),
      ),
      courseDetail => switch (settings.arguments) {
        final CourseDetailArguments args => BlocProvider(
          create: (_) =>
              serviceLocator<CourseDetailBloc>(param1: args.courseId)
                ..add(const CourseDetailStarted()),
          child: CourseDetailPage(courseTitle: args.courseTitle),
        ),
        _ => const ErrorPage(),
      },
      _ => const ErrorPage(),
    };
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) =>
      MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const ErrorPage(),
      );
}
