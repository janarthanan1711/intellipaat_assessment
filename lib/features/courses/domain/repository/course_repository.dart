import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../model/course.dart';
import '../model/course_detail.dart';

/// Offline-first: the local database is the single source of truth.
/// `watch*` streams always serve what is stored on the device; `refresh*`
/// pulls from the network into storage, which in turn updates the streams.
abstract interface class CourseRepository {
  Stream<List<Course>> watchCourses();

  /// Emits null if the course isn't stored locally.
  Stream<CourseDetail?> watchCourseDetail(int courseId);

  Future<Either<Failure, Unit>> refreshCourses();

  Future<Either<Failure, Unit>> refreshLessons(int courseId);

  /// Saves the completion locally first (works offline), then tries to sync.
  Future<Either<Failure, CompletionSync>> completeLesson({
    required int courseId,
    required int lessonId,
  });
}
