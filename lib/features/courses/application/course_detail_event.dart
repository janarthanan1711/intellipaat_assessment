part of 'course_detail_bloc.dart';

sealed class CourseDetailEvent extends Equatable {
  const CourseDetailEvent();

  @override
  List<Object?> get props => [];
}

final class CourseDetailStarted extends CourseDetailEvent {
  const CourseDetailStarted();
}

final class CourseDetailRefreshRequested extends CourseDetailEvent {
  const CourseDetailRefreshRequested();
}

final class LessonCompletionRequested extends CourseDetailEvent {
  const LessonCompletionRequested(this.lessonId);

  final int lessonId;

  @override
  List<Object?> get props => [lessonId];
}
