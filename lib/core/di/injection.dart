import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import '../../common/app_constants.dart';
import '../../common/app_routes.dart';
import '../../features/auth/application/login_bloc.dart';
import '../../features/auth/data/repo_implementation/auth_repo_impl.dart';
import '../../features/auth/data/repository/auth_api.dart';
import '../../features/auth/domain/repository/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecase.dart';
import '../../features/courses/application/course_detail_bloc.dart';
import '../../features/courses/application/dashboard_bloc.dart';
import '../../features/courses/data/local/course_local_data_source.dart';
import '../../features/courses/data/repo_implementation/course_repo_impl.dart';
import '../../features/courses/data/repository/course_api.dart';
import '../../features/courses/domain/repository/course_repository.dart';
import '../../features/courses/domain/usecases/course_usecase.dart';
import '../network/network.dart';
import '../services/navigation_service.dart';
import '../storage/app_database.dart';
import '../storage/session_storage.dart';

/// Publicly assignable so tests can register fakes.
GetIt serviceLocator = GetIt.instance;

/// Blocs are factories (a fresh one per screen); everything below them is a
/// lazy singleton.
Future<void> init() async {
  serviceLocator
    ..registerLazySingleton<NavigationService>(NavigationService.new)
    ..registerLazySingleton<SessionStorage>(SecureSessionStorage.new)
    ..registerLazySingleton<AppDatabase>(AppDatabase.new)
    ..registerLazySingleton<Connectivity>(Connectivity.new)
    ..registerLazySingleton<ApiManager>(
      () => DioProviderImpl(
        interceptors: [
          AuthInterceptor(
            sessionStorage: serviceLocator(),
            onUnauthorized: _onSessionExpired,
          ),
          if (AppConstants.useMockApi)
            MockApiInterceptor(connectivity: serviceLocator()),
        ],
      ),
    );

  // auth
  serviceLocator
    ..registerFactory<LoginBloc>(() => LoginBloc(serviceLocator()))
    ..registerLazySingleton<AuthApi>(() => AuthApi(serviceLocator()))
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepoImpl(serviceLocator(), serviceLocator(), serviceLocator()),
    )
    ..registerLazySingleton<AuthUsecase>(() => AuthUsecase(serviceLocator()));

  // courses
  serviceLocator
    ..registerFactory<DashboardBloc>(
      () => DashboardBloc(serviceLocator(), serviceLocator()),
    )
    ..registerFactoryParam<CourseDetailBloc, int, void>(
      (courseId, _) => CourseDetailBloc(serviceLocator(), courseId: courseId),
    )
    ..registerLazySingleton<CourseApi>(() => CourseApi(serviceLocator()))
    ..registerLazySingleton<CourseLocalDataSource>(
      () => SqfliteCourseLocalDataSource(serviceLocator()),
    )
    ..registerLazySingleton<CourseRepository>(
      () => CourseRepoImpl(serviceLocator(), serviceLocator()),
    )
    ..registerLazySingleton<CourseUsecase>(
      () => CourseUsecase(serviceLocator()),
    );
}

/// The server rejected our token: drop the session and return to login.
Future<void> _onSessionExpired() async {
  await serviceLocator<SessionStorage>().clear();
  serviceLocator<NavigationService>().resetTo(AppRoutes.login);
}
