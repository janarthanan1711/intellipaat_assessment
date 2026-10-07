abstract final class ApiEndpoints {
  static const login = '/auth/login';
  static const courses = '/courses';

  static String courseLessons(int courseId) => '/courses/$courseId/lessons';

  static String completeLesson(int lessonId) => '/lessons/$lessonId/complete';
}
