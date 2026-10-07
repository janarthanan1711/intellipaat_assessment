import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learning_dashboard/common/app_routes.dart';
import 'package:learning_dashboard/core/di/injection.dart';
import 'package:learning_dashboard/core/error/failures.dart';
import 'package:learning_dashboard/features/auth/domain/usecases/auth_usecase.dart';
import 'package:learning_dashboard/features/courses/application/course_detail_bloc.dart';
import 'package:learning_dashboard/features/courses/application/dashboard_bloc.dart';
import 'package:learning_dashboard/features/courses/domain/model/course.dart';
import 'package:learning_dashboard/features/courses/domain/model/course_detail.dart';
import 'package:learning_dashboard/features/courses/domain/model/lesson.dart';
import 'package:learning_dashboard/features/courses/domain/progress_calculator.dart';
import 'package:learning_dashboard/features/courses/domain/repository/course_repository.dart';
import 'package:learning_dashboard/features/courses/domain/usecases/course_usecase.dart';

import 'fakes.dart';

/// Reactive in-memory repository: completing a lesson re-emits on both
/// streams, the way the SQLite store does.
class InMemoryCourseRepository implements CourseRepository {
  Course _course = const Course(
    id: 1,
    title: 'Python Programming',
    instructor: 'John Smith',
    progress: 50,
    lessonCount: 2,
  );
  List<Lesson> _lessons = const [
    Lesson(id: 101, title: 'Introduction', isCompleted: true),
    Lesson(id: 102, title: 'Functions', isCompleted: false),
  ];
  final _changes = StreamController<void>.broadcast();

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Stream<List<Course>> watchCourses() => _watch(() => [_course]);

  @override
  Stream<CourseDetail?> watchCourseDetail(int courseId) =>
      _watch(() => CourseDetail(course: _course, lessons: _lessons));

  @override
  Future<Either<Failure, Unit>> refreshCourses() async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> refreshLessons(int courseId) async =>
      const Right(unit);

  @override
  Future<Either<Failure, CompletionSync>> completeLesson({
    required int courseId,
    required int lessonId,
  }) async {
    _lessons = [
      for (final l in _lessons)
        l.id == lessonId
            ? Lesson(id: l.id, title: l.title, isCompleted: true)
            : l,
    ];
    _course = Course(
      id: _course.id,
      title: _course.title,
      instructor: _course.instructor,
      progress: ProgressCalculator.percent(
        completed: _lessons.where((l) => l.isCompleted).length,
        total: _lessons.length,
      ),
      lessonCount: _lessons.length,
    );
    _changes.add(null);
    return const Right(CompletionSync.pendingSync);
  }
}

void main() {
  setUp(() {
    final usecase = CourseUsecase(InMemoryCourseRepository());
    serviceLocator
      ..registerFactory<DashboardBloc>(
        () => DashboardBloc(usecase, FakeAuthUsecase(const Right(unit))),
      )
      ..registerFactoryParam<CourseDetailBloc, int, void>(
        (courseId, _) => CourseDetailBloc(usecase, courseId: courseId),
      )
      ..registerSingleton<AuthUsecase>(FakeAuthUsecase(const Right(unit)));
  });

  tearDown(() => serviceLocator.reset());

  testWidgets(
    'dashboard -> course details -> mark lesson complete updates status and progress',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          initialRoute: AppRoutes.dashboard,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Python Programming'), findsOneWidget);
      expect(find.text('John Smith'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('2 lessons'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 lessons completed'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      await tester.tap(find.text('Mark complete'));
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsNothing);
      expect(find.text('2 of 2 lessons completed'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      // Completion was saved locally but not synced -> user is told.
      expect(find.textContaining('Saved on this device'), findsOneWidget);

      // Back on the dashboard the course reflects the new progress.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    },
  );
}
