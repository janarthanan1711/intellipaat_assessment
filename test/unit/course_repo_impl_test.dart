import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learning_dashboard/core/error/failures.dart';
import 'package:learning_dashboard/core/network/network.dart';
import 'package:learning_dashboard/core/storage/app_database.dart';
import 'package:learning_dashboard/features/courses/data/local/course_local_data_source.dart';
import 'package:learning_dashboard/features/courses/data/repo_implementation/course_repo_impl.dart';
import 'package:learning_dashboard/features/courses/data/repository/course_api.dart';
import 'package:learning_dashboard/features/courses/domain/model/course_detail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Stateless fake backend, like the real mock: it never learns about
/// completions, so anything the app shows beyond this data came from the
/// local merge.
class FakeApiManager implements ApiManager {
  bool offline = false;
  final postedPaths = <String>[];

  static const courses = [
    {
      'id': 1,
      'title': 'Python Programming',
      'instructor': 'John Smith',
      'progress': 25,
      'lessons': 4,
    },
    {
      'id': 2,
      'title': 'Generative AI',
      'instructor': 'Sarah Williams',
      'progress': 0,
      'lessons': 2,
    },
  ];

  static const pythonLessons = [
    {'id': 101, 'title': 'Introduction', 'completed': true},
    {'id': 102, 'title': 'Variables & Data Types', 'completed': false},
    {'id': 103, 'title': 'Functions', 'completed': false},
    {'id': 104, 'title': 'OOP', 'completed': false},
  ];

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final options = _checkOnline(path);
    final data = switch (path) {
      ApiEndpoints.courses => courses,
      '/courses/1/lessons' => pythonLessons,
      _ => throw StateError('Unexpected GET $path'),
    };
    return Response<dynamic>(
      requestOptions: options,
      statusCode: 200,
      data: data,
    );
  }

  @override
  Future<Response<dynamic>> post(String path, {Object? data}) async {
    final options = _checkOnline(path);
    postedPaths.add(path);
    return Response<dynamic>(requestOptions: options, statusCode: 200);
  }

  RequestOptions _checkOnline(String path) {
    final options = RequestOptions(path: path);
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return options;
  }
}

void main() {
  sqfliteFfiInit();

  late FakeApiManager api;
  late AppDatabase database;
  late SqfliteCourseLocalDataSource local;
  late CourseRepoImpl repository;

  setUp(() {
    api = FakeApiManager();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    local = SqfliteCourseLocalDataSource(database);
    repository = CourseRepoImpl(CourseApi(api), local);
  });

  tearDown(() => database.close());

  Future<CourseDetail> python() async =>
      (await repository.watchCourseDetail(1).first)!;

  test(
    'keeps serving previously loaded courses when the device goes offline',
    () async {
      expect(
        await repository.refreshCourses(),
        const Right<Failure, Unit>(unit),
      );

      api.offline = true;
      final result = await repository.refreshCourses();

      expect(result, const Left<Failure, Unit>(NetworkFailure()));
      final cached = await repository.watchCourses().first;
      expect(cached.map((c) => c.title), [
        'Python Programming',
        'Generative AI',
      ]);
    },
  );

  test(
    'a lesson completed offline updates progress at once, survives a refresh '
    'from a server that has not seen it, and is synced when back online',
    () async {
      await repository.refreshCourses();
      await repository.refreshLessons(1);
      expect((await python()).course.progress, 25); // 1 of 4

      api.offline = true;
      final completion = await repository.completeLesson(
        courseId: 1,
        lessonId: 102,
      );

      expect(
        completion,
        const Right<Failure, CompletionSync>(CompletionSync.pendingSync),
      );
      var detail = await python();
      expect(detail.lessons.firstWhere((l) => l.id == 102).isCompleted, isTrue);
      expect(detail.course.progress, 50); // 2 of 4, without any network

      api.offline = false;
      await repository.refreshLessons(1);
      await repository.refreshCourses();

      // The queued completion reached the server...
      expect(api.postedPaths, ['/lessons/102/complete']);
      expect(await local.pendingCompletionIds(), isEmpty);
      // ...and the server's stale copy (lesson 102 pending, 25%) did not
      // overwrite local progress, on either screen.
      detail = await python();
      expect(detail.lessons.firstWhere((l) => l.id == 102).isCompleted, isTrue);
      expect(detail.course.progress, 50);
      final dashboard = await repository.watchCourses().first;
      expect(dashboard.firstWhere((c) => c.id == 1).progress, 50);
    },
  );
}
