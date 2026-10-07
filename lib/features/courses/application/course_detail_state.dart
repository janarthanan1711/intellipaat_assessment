part of 'course_detail_bloc.dart';

enum CourseDetailStatus { loading, content, empty, failure, notFound }

/// One-off messages for the UI (shown as snackbars).
enum CourseDetailNotice { savedOffline, completionFailed }

final class CourseDetailState extends Equatable {
  const CourseDetailState({
    this.detail,
    this.cacheLoaded = false,
    this.isRefreshing = false,
    this.refreshFailure,
    this.completingLessonIds = const {},
    this.notice,
    this.noticeId = 0,
  });

  final CourseDetail? detail;
  final bool cacheLoaded;
  final bool isRefreshing;
  final Failure? refreshFailure;

  /// Lessons whose completion is still being saved/synced.
  final Set<int> completingLessonIds;

  /// Latest notice; [noticeId] increments with each one so the same notice
  /// twice in a row is still delivered.
  final CourseDetailNotice? notice;
  final int noticeId;

  CourseDetailStatus get status {
    final detail = this.detail;
    if (detail != null && detail.lessons.isNotEmpty) {
      return CourseDetailStatus.content;
    }
    if (!cacheLoaded || isRefreshing) return CourseDetailStatus.loading;
    if (refreshFailure != null) return CourseDetailStatus.failure;
    if (detail == null) return CourseDetailStatus.notFound;
    return CourseDetailStatus.empty;
  }

  bool get isOffline => refreshFailure is NetworkFailure;

  /// Passing a [notice] publishes it as a new notice.
  CourseDetailState copyWith({
    CourseDetail? Function()? detail,
    bool? cacheLoaded,
    bool? isRefreshing,
    Failure? Function()? refreshFailure,
    Set<int>? completingLessonIds,
    CourseDetailNotice? notice,
  }) {
    return CourseDetailState(
      detail: detail != null ? detail() : this.detail,
      cacheLoaded: cacheLoaded ?? this.cacheLoaded,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshFailure: refreshFailure != null
          ? refreshFailure()
          : this.refreshFailure,
      completingLessonIds: completingLessonIds ?? this.completingLessonIds,
      notice: notice ?? this.notice,
      noticeId: notice != null ? noticeId + 1 : noticeId,
    );
  }

  @override
  List<Object?> get props => [
    detail,
    cacheLoaded,
    isRefreshing,
    refreshFailure,
    completingLessonIds,
    notice,
    noticeId,
  ];
}
