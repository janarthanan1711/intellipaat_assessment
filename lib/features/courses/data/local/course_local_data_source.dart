import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/model/course.dart';
import '../../domain/model/course_detail.dart';
import '../../domain/model/lesson.dart';
import '../../domain/progress_calculator.dart';

abstract interface class CourseLocalDataSource {
  Stream<List<Course>> watchCourses();

  Stream<CourseDetail?> watchCourseDetail(int courseId);

  /// Replaces the stored course list with [courses].
  Future<void> saveCourses(List<Course> courses);

  /// Replaces the stored lessons of [courseId] with [lessons].
  Future<void> saveLessons(int courseId, List<Lesson> lessons);

  /// Marks a lesson completed and queues it for sync. Returns false if it was
  /// already completed (or doesn't exist).
  Future<bool> markLessonCompleted({
    required int courseId,
    required int lessonId,
  });

  Future<List<int>> pendingCompletionIds();

  Future<void> clearPendingCompletion(int lessonId);
}

/// SQLite-backed store. Every write runs in a transaction and is followed by
/// a change notification, which re-runs the queries behind active `watch*`
/// streams.
///
/// Merge rules, applied whenever server data is saved:
/// * Completion is one-way: a lesson completed on this device stays completed
///   even if the server's copy hasn't caught up yet.
/// * Once a course's lessons are stored, its progress and lesson count are
///   derived from them instead of the server's summary.
class SqfliteCourseLocalDataSource implements CourseLocalDataSource {
  SqfliteCourseLocalDataSource(this._appDatabase);

  static const _courses = AppDatabase.coursesTable;
  static const _lessons = AppDatabase.lessonsTable;

  final AppDatabase _appDatabase;
  final _changes = StreamController<void>.broadcast(sync: true);

  @override
  Stream<List<Course>> watchCourses() => _watch(_readCourses);

  @override
  Stream<CourseDetail?> watchCourseDetail(int courseId) =>
      _watch(() => _readCourseDetail(courseId));

  @override
  Future<void> saveCourses(List<Course> courses) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      final ids = [for (final course in courses) course.id];
      if (ids.isEmpty) {
        await txn.delete(_lessons);
        await txn.delete(_courses);
      } else {
        final placeholders = List.filled(ids.length, '?').join(',');
        await txn.delete(
          _courses,
          where: 'id NOT IN ($placeholders)',
          whereArgs: ids,
        );
        await txn.delete(
          _lessons,
          where: 'course_id NOT IN ($placeholders)',
          whereArgs: ids,
        );
      }
      for (final (index, course) in courses.indexed) {
        await txn.insert(
          _courses,
          _courseToRow(course, sortOrder: index),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await _syncCourseProgress(txn, course.id);
      }
    });
    _changes.add(null);
  }

  @override
  Future<void> saveLessons(int courseId, List<Lesson> lessons) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      final existing = await txn.query(
        _lessons,
        columns: ['id', 'is_completed', 'pending_sync'],
        where: 'course_id = ?',
        whereArgs: [courseId],
      );
      final completedLocally = {
        for (final row in existing)
          if (row['is_completed'] == 1) row['id']! as int,
      };
      final pendingSync = {
        for (final row in existing)
          if (row['pending_sync'] == 1) row['id']! as int,
      };

      await txn.delete(_lessons, where: 'course_id = ?', whereArgs: [courseId]);
      final batch = txn.batch();
      for (final (position, lesson) in lessons.indexed) {
        final completed =
            lesson.isCompleted || completedLocally.contains(lesson.id);
        batch.insert(_lessons, {
          'id': lesson.id,
          'course_id': courseId,
          'title': lesson.title,
          'position': position,
          'is_completed': completed ? 1 : 0,
          'pending_sync': pendingSync.contains(lesson.id) ? 1 : 0,
        });
      }
      await batch.commit(noResult: true);
      await _syncCourseProgress(txn, courseId);
    });
    _changes.add(null);
  }

  @override
  Future<bool> markLessonCompleted({
    required int courseId,
    required int lessonId,
  }) async {
    final db = await _appDatabase.database;
    final changed = await db.transaction((txn) async {
      final updated = await txn.update(
        _lessons,
        {'is_completed': 1, 'pending_sync': 1},
        where: 'id = ? AND course_id = ? AND is_completed = 0',
        whereArgs: [lessonId, courseId],
      );
      if (updated == 0) return false;
      await _syncCourseProgress(txn, courseId);
      return true;
    });
    if (changed) _changes.add(null);
    return changed;
  }

  @override
  Future<List<int>> pendingCompletionIds() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      _lessons,
      columns: ['id'],
      where: 'pending_sync = 1',
      orderBy: 'id',
    );
    return [for (final row in rows) row['id']! as int];
  }

  @override
  Future<void> clearPendingCompletion(int lessonId) async {
    final db = await _appDatabase.database;
    await db.update(
      _lessons,
      {'pending_sync': 0},
      where: 'id = ?',
      whereArgs: [lessonId],
    );
  }

  /// Recomputes a course's progress from its stored lessons, inside the same
  /// transaction as the write that changed them so concurrent completions
  /// can't produce a stale percentage.
  Future<void> _syncCourseProgress(Transaction txn, int courseId) async {
    final rows = await txn.rawQuery(
      'SELECT COUNT(*) AS total, COALESCE(SUM(is_completed), 0) AS completed '
      'FROM $_lessons WHERE course_id = ?',
      [courseId],
    );
    final total = rows.first['total']! as int;
    final completed = rows.first['completed']! as int;
    // No lessons stored yet: keep the server's summary.
    if (total == 0) return;
    await txn.update(
      _courses,
      {
        'progress': ProgressCalculator.percent(
          completed: completed,
          total: total,
        ),
        'lesson_count': total,
      },
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  Future<List<Course>> _readCourses() async {
    final db = await _appDatabase.database;
    final rows = await db.query(_courses, orderBy: 'sort_order');
    return rows.map(_courseFromRow).toList();
  }

  Future<CourseDetail?> _readCourseDetail(int courseId) async {
    final db = await _appDatabase.database;
    final courseRows = await db.query(
      _courses,
      where: 'id = ?',
      whereArgs: [courseId],
      limit: 1,
    );
    if (courseRows.isEmpty) return null;
    final lessonRows = await db.query(
      _lessons,
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'position',
    );
    return CourseDetail(
      course: _courseFromRow(courseRows.first),
      lessons: lessonRows.map(_lessonFromRow).toList(),
    );
  }

  /// Emits [query]'s result on listen and again after every write.
  /// `asyncMap` runs queries one at a time, so results arrive in order.
  Stream<T> _watch<T>(Future<T> Function() query) {
    StreamSubscription<void>? changes;
    late final StreamController<void> triggers;
    triggers = StreamController<void>(
      onListen: () {
        changes = _changes.stream.listen(triggers.add);
        triggers.add(null);
      },
      onCancel: () async {
        await changes?.cancel();
        await triggers.close();
      },
    );
    return triggers.stream.asyncMap((_) => query());
  }

  static Map<String, Object?> _courseToRow(
    Course course, {
    required int sortOrder,
  }) => {
    'id': course.id,
    'title': course.title,
    'instructor': course.instructor,
    'progress': course.progress,
    'lesson_count': course.lessonCount,
    'sort_order': sortOrder,
  };

  static Course _courseFromRow(Map<String, Object?> row) => Course(
    id: row['id']! as int,
    title: row['title']! as String,
    instructor: row['instructor']! as String,
    progress: row['progress']! as int,
    lessonCount: row['lesson_count']! as int,
  );

  static Lesson _lessonFromRow(Map<String, Object?> row) => Lesson(
    id: row['id']! as int,
    title: row['title']! as String,
    isCompleted: row['is_completed'] == 1,
  );
}
