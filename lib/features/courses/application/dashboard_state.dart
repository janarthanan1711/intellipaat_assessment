part of 'dashboard_bloc.dart';

enum DashboardStatus { loading, content, empty, failure }

final class DashboardState extends Equatable {
  const DashboardState({
    this.courses = const [],
    this.cacheLoaded = false,
    this.isRefreshing = false,
    this.refreshFailure,
    this.loggedOut = false,
  });

  /// What is stored on the device — the single source of truth.
  final List<Course> courses;

  /// Whether the first read from local storage has completed.
  final bool cacheLoaded;
  final bool isRefreshing;

  /// Why the latest network refresh failed, if it did.
  final Failure? refreshFailure;
  final bool loggedOut;

  /// Cached courses always win: a failed refresh with data on the device is
  /// content plus a banner, not an error screen.
  DashboardStatus get status {
    if (courses.isNotEmpty) return DashboardStatus.content;
    if (!cacheLoaded || isRefreshing) return DashboardStatus.loading;
    if (refreshFailure != null) return DashboardStatus.failure;
    return DashboardStatus.empty;
  }

  bool get isOffline => refreshFailure is NetworkFailure;

  DashboardState copyWith({
    List<Course>? courses,
    bool? cacheLoaded,
    bool? isRefreshing,
    Failure? Function()? refreshFailure,
    bool? loggedOut,
  }) {
    return DashboardState(
      courses: courses ?? this.courses,
      cacheLoaded: cacheLoaded ?? this.cacheLoaded,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshFailure: refreshFailure != null
          ? refreshFailure()
          : this.refreshFailure,
      loggedOut: loggedOut ?? this.loggedOut,
    );
  }

  @override
  List<Object?> get props => [
    courses,
    cacheLoaded,
    isRefreshing,
    refreshFailure,
    loggedOut,
  ];
}
