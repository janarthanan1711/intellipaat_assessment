import 'package:equatable/equatable.dart';

import 'course.dart';
import 'lesson.dart';

class CourseDetail extends Equatable {
  const CourseDetail({required this.course, required this.lessons});

  final Course course;
  final List<Lesson> lessons;

  int get completedCount =>
      lessons.where((lesson) => lesson.isCompleted).length;

  @override
  List<Object?> get props => [course, lessons];
}

/// Whether a lesson completion has reached the server yet.
enum CompletionSync { synced, pendingSync }
