import 'package:dio/dio.dart';

import '../../../../core/network/network.dart';

/// Transport only: builds requests, returns raw responses.
class CourseApi {
  const CourseApi(this._apiManager);

  final ApiManager _apiManager;

  Future<Response<dynamic>> fetchCourses() =>
      _apiManager.get(ApiEndpoints.courses);

  Future<Response<dynamic>> fetchLessons(int courseId) =>
      _apiManager.get(ApiEndpoints.courseLessons(courseId));

  Future<Response<dynamic>> completeLesson(int lessonId) =>
      _apiManager.post(ApiEndpoints.completeLesson(lessonId));
}
