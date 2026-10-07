import 'package:flutter/material.dart';

import '../common/app_constants.dart';
import '../common/app_routes.dart';
import '../common/app_themes.dart';
import '../core/di/injection.dart';
import '../core/services/navigation_service.dart';

class LearningDashboardApp extends StatelessWidget {
  const LearningDashboardApp({super.key, required this.initialRoute});

  /// Decided at startup from the stored session, so there is no splash
  /// screen and no flash of the login page for a signed-in user.
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      navigatorKey: serviceLocator<NavigationService>().navigatorKey,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      onUnknownRoute: AppRoutes.onUnknownRoute,
      // `initialRoute` would also push '/' beneath any '/x' route; build the
      // single starting route explicitly instead.
      onGenerateInitialRoutes: (_) => [
        AppRoutes.onGenerateRoute(RouteSettings(name: initialRoute)),
      ],
    );
  }
}
