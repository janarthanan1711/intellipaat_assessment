import 'package:equatable/equatable.dart';

import '../progress_calculator.dart';

class Course extends Equatable {
  const Course({
    required this.id,
    required this.title,
    required this.instructor,
    required this.progress,
    required this.lessonCount,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'] as int,
    title: json['title'] as String,
    instructor: json['instructor'] as String,
    progress: ProgressCalculator.clamp((json['progress'] as num).round()),
    lessonCount: json['lessons'] as int,
  );

  final int id;
  final String title;
  final String instructor;

  /// Completion percentage, 0–100.
  final int progress;
  final int lessonCount;

  @override
  List<Object?> get props => [id, title, instructor, progress, lessonCount];
}
