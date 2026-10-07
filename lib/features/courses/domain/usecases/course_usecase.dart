import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../model/course.dart';
import '../model/course_detail.dart';
import '../repository/course_repository.dart';

class CourseUsecase {
  const CourseUsecase(this._repository);

  final CourseRepository _repository;

  Stream<List<Course>> watchCourses() => _repository.watchCourses();

  Future<Either<Failure, Unit>> refreshCourses() =>
      _repository.refreshCourses();

  Stream<CourseDetail?> watchCourseDetail(int courseId) =>
      _repository.watchCourseDetail(courseId);

  Future<Either<Failure, Unit>> refreshLessons(int courseId) =>
      _repository.refreshLessons(courseId);

  Future<Either<Failure, CompletionSync>> completeLesson({
    required int courseId,
    required int lessonId,
  }) => _repository.completeLesson(courseId: courseId, lessonId: lessonId);
}
