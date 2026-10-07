import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../domain/model/course_detail.dart';
import '../domain/usecases/course_usecase.dart';

part 'course_detail_event.dart';
part 'course_detail_state.dart';

class CourseDetailBloc extends Bloc<CourseDetailEvent, CourseDetailState> {
  CourseDetailBloc(this._courseUsecase, {required this.courseId})
    : super(const CourseDetailState()) {
    on<CourseDetailStarted>(_onStarted);
    on<CourseDetailRefreshRequested>(_onRefreshRequested);
    on<LessonCompletionRequested>(_onLessonCompletionRequested);
  }

  final CourseUsecase _courseUsecase;
  final int courseId;

  Future<void> _onStarted(
    CourseDetailStarted event,
    Emitter<CourseDetailState> emit,
  ) async {
    add(const CourseDetailRefreshRequested());
    await emit.forEach<CourseDetail?>(
      _courseUsecase.watchCourseDetail(courseId),
      onData: (detail) =>
          state.copyWith(detail: () => detail, cacheLoaded: true),
      onError: (_, _) => state.copyWith(
        cacheLoaded: true,
        refreshFailure: () => const CacheFailure(),
      ),
    );
  }

  Future<void> _onRefreshRequested(
    CourseDetailRefreshRequested event,
    Emitter<CourseDetailState> emit,
  ) async {
    if (state.isRefreshing) return;
    emit(state.copyWith(isRefreshing: true, refreshFailure: () => null));
    final result = await _courseUsecase.refreshLessons(courseId);
    emit(
      state.copyWith(
        isRefreshing: false,
        refreshFailure: () => result.fold((failure) => failure, (_) => null),
      ),
    );
  }

  /// The lesson and the course progress update through the database stream as
  /// soon as the local write lands; this handler only tracks the in-flight
  /// sync and reports how it ended.
  Future<void> _onLessonCompletionRequested(
    LessonCompletionRequested event,
    Emitter<CourseDetailState> emit,
  ) async {
    final lessonId = event.lessonId;
    if (state.completingLessonIds.contains(lessonId)) return;
    emit(
      state.copyWith(
        completingLessonIds: {...state.completingLessonIds, lessonId},
      ),
    );

    final result = await _courseUsecase.completeLesson(
      courseId: courseId,
      lessonId: lessonId,
    );
    final notice = result.fold(
      (_) => CourseDetailNotice.completionFailed,
      (sync) => sync == CompletionSync.pendingSync
          ? CourseDetailNotice.savedOffline
          : null,
    );
    emit(
      state.copyWith(
        completingLessonIds: {...state.completingLessonIds}..remove(lessonId),
        notice: notice,
      ),
    );
  }
}
