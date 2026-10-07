import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learning_dashboard/core/error/failures.dart';
import 'package:learning_dashboard/features/courses/application/dashboard_bloc.dart';
import 'package:learning_dashboard/features/courses/domain/model/course.dart';
import 'package:learning_dashboard/features/courses/domain/model/course_detail.dart';
import 'package:learning_dashboard/features/courses/domain/repository/course_repository.dart';
import 'package:learning_dashboard/features/courses/domain/usecases/course_usecase.dart';

import 'fakes.dart';

class FakeCourseRepository implements CourseRepository {
  FakeCourseRepository({required this.cached, required this.refreshResult});

  final List<Course> cached;
  final Either<Failure, Unit> refreshResult;

  @override
  Stream<List<Course>> watchCourses() => Stream.value(cached);

  @override
  Future<Either<Failure, Unit>> refreshCourses() async => refreshResult;

  @override
  Stream<CourseDetail?> watchCourseDetail(int courseId) => const Stream.empty();

  @override
  Future<Either<Failure, Unit>> refreshLessons(int courseId) async =>
      refreshResult;

  @override
  Future<Either<Failure, CompletionSync>> completeLesson({
    required int courseId,
    required int lessonId,
  }) async => const Right(CompletionSync.synced);
}

void main() {
  const course = Course(
    id: 1,
    title: 'Python Programming',
    instructor: 'John Smith',
    progress: 65,
    lessonCount: 20,
  );

  DashboardBloc build(FakeCourseRepository repository) => DashboardBloc(
    CourseUsecase(repository),
    FakeAuthUsecase(const Right(unit)),
  );

  /// Starts the bloc and lets both the cache read and the refresh finish.
  Future<DashboardState> settle(DashboardBloc bloc) async {
    bloc.add(const DashboardStarted());
    await pumpEventQueue();
    return bloc.state;
  }

  test(
    'offline with cached courses shows them with an offline banner',
    () async {
      final bloc = build(
        FakeCourseRepository(
          cached: [course],
          refreshResult: const Left(NetworkFailure()),
        ),
      );

      final state = await settle(bloc);

      expect(state.status, DashboardStatus.content);
      expect(state.courses, [course]);
      expect(state.isOffline, isTrue);
      await bloc.close();
    },
  );

  test(
    'offline with nothing cached is an error state, not an empty list',
    () async {
      final bloc = build(
        FakeCourseRepository(
          cached: const [],
          refreshResult: const Left(NetworkFailure()),
        ),
      );

      expect((await settle(bloc)).status, DashboardStatus.failure);
      await bloc.close();
    },
  );

  test('a successful load with no courses is the empty state', () async {
    final bloc = build(
      FakeCourseRepository(cached: const [], refreshResult: const Right(unit)),
    );

    expect((await settle(bloc)).status, DashboardStatus.empty);
    await bloc.close();
  });

  blocTest<DashboardBloc, DashboardState>(
    'is loading until local storage has answered',
    build: () => build(
      FakeCourseRepository(cached: const [], refreshResult: const Right(unit)),
    ),
    verify: (bloc) => expect(bloc.state.status, DashboardStatus.loading),
  );
}
