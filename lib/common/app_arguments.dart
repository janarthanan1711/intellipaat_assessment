/// Typed arguments for routes that take them.
class CourseDetailArguments {
  const CourseDetailArguments({
    required this.courseId,
    required this.courseTitle,
  });

  final int courseId;

  /// Shown in the app bar before the course has loaded.
  final String courseTitle;
}
