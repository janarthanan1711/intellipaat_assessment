import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../auth/domain/usecases/auth_usecase.dart';
import '../domain/model/course.dart';
import '../domain/usecases/course_usecase.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._courseUsecase, this._authUsecase)
    : super(const DashboardState()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardRefreshRequested>(_onRefreshRequested);
    on<DashboardLogoutRequested>(_onLogoutRequested);
  }

  final CourseUsecase _courseUsecase;
  final AuthUsecase _authUsecase;

  /// Shows stored courses immediately and keeps following the database,
  /// while a network refresh runs alongside.
  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    add(const DashboardRefreshRequested());
    await emit.forEach<List<Course>>(
      _courseUsecase.watchCourses(),
      onData: (courses) => state.copyWith(courses: courses, cacheLoaded: true),
      onError: (_, _) => state.copyWith(
        cacheLoaded: true,
        refreshFailure: () => const CacheFailure(),
      ),
    );
  }

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.isRefreshing) return;
    emit(state.copyWith(isRefreshing: true, refreshFailure: () => null));
    final result = await _courseUsecase.refreshCourses();
    emit(
      state.copyWith(
        isRefreshing: false,
        refreshFailure: () => result.fold((failure) => failure, (_) => null),
      ),
    );
  }

  Future<void> _onLogoutRequested(
    DashboardLogoutRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _authUsecase.logout();
    emit(state.copyWith(loggedOut: true));
  }
}
