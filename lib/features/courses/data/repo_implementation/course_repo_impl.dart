import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/error/error_reporter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network.dart';
import '../../domain/model/course.dart';
import '../../domain/model/course_detail.dart';
import '../../domain/model/lesson.dart';
import '../../domain/repository/course_repository.dart';
import '../local/course_local_data_source.dart';
import '../repository/course_api.dart';

class CourseRepoImpl implements CourseRepository {
  CourseRepoImpl(this._api, this._local);

  final CourseApi _api;
  final CourseLocalDataSource _local;

  @override
  Stream<List<Course>> watchCourses() => _local.watchCourses();

  @override
  Stream<CourseDetail?> watchCourseDetail(int courseId) =>
      _local.watchCourseDetail(courseId);

  @override
  Future<Either<Failure, Unit>> refreshCourses() => _guard(() async {
    await _pushPendingCompletions();
    final response = await _api.fetchCourses();
    await _local.saveCourses(_parseList(response.data, Course.fromJson));
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> refreshLessons(int courseId) =>
      _guard(() async {
        await _pushPendingCompletions();
        final response = await _api.fetchLessons(courseId);
        await _local.saveLessons(
          courseId,
          _parseList(response.data, Lesson.fromJson),
        );
        return unit;
      });

  @override
  Future<Either<Failure, CompletionSync>> completeLesson({
    required int courseId,
    required int lessonId,
  }) async {
    final bool changed;
    try {
      changed = await _local.markLessonCompleted(
        courseId: courseId,
        lessonId: lessonId,
      );
    } on DatabaseException catch (e, s) {
      ErrorReporter.report(e, s, reason: 'Saving lesson completion failed');
      return const Left(CacheFailure());
    }
    if (!changed) return const Right(CompletionSync.synced);

    try {
      await _api.completeLesson(lessonId);
      await _local.clearPendingCompletion(lessonId);
      return const Right(CompletionSync.synced);
    } on DioException {
      // Already saved locally; it is retried on the next refresh.
      return const Right(CompletionSync.pendingSync);
    }
  }

  /// Sends completions made while offline. A network error aborts (the
  /// caller's refresh would fail anyway); a server rejection of one item
  /// leaves it queued without blocking the rest.
  Future<void> _pushPendingCompletions() async {
    for (final lessonId in await _local.pendingCompletionIds()) {
      try {
        await _api.completeLesson(lessonId);
        await _local.clearPendingCompletion(lessonId);
      } on DioException catch (e, s) {
        if (DioErrorHandler.isNetworkError(e)) rethrow;
        ErrorReporter.report(e, s, reason: 'Lesson $lessonId sync rejected');
      }
    }
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      return Left(DioErrorHandler.toFailure(e));
    } on FormatException catch (e, s) {
      ErrorReporter.report(e, s, reason: 'Unexpected response shape');
      return const Left(ParsingFailure());
    } on DatabaseException catch (e, s) {
      ErrorReporter.report(e, s, reason: 'Local database error');
      return const Left(CacheFailure());
    }
  }

  static List<T> _parseList<T>(
    Object? data,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (data is! List) throw const FormatException('Expected a JSON array');
    try {
      return [for (final item in data) fromJson(item as Map<String, dynamic>)];
    } on TypeError catch (e) {
      // Missing or wrongly typed field in the payload.
      throw FormatException('Malformed item: $e');
    }
  }
}
