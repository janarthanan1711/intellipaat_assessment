import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/info_banner.dart';
import '../../../../core/utils/status_view.dart';
import '../../application/course_detail_bloc.dart';
import '../widgets/course_progress_header.dart';
import '../widgets/lesson_tile.dart';

class CourseDetailPage extends StatelessWidget {
  const CourseDetailPage({super.key, required this.courseTitle});

  final String courseTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(courseTitle)),
      body: BlocConsumer<CourseDetailBloc, CourseDetailState>(
        listenWhen: (previous, current) =>
            previous.noticeId != current.noticeId,
        listener: _showNotice,
        builder: (context, state) => switch (state.status) {
          CourseDetailStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          CourseDetailStatus.content => _LessonList(state: state),
          CourseDetailStatus.empty => StatusView(
            icon: Icons.menu_book_outlined,
            title: 'No lessons yet',
            message: 'Lessons for this course will appear here.',
            actionLabel: 'Refresh',
            onAction: () => _refresh(context),
          ),
          CourseDetailStatus.failure => StatusView(
            icon: state.isOffline ? Icons.cloud_off : Icons.error_outline,
            title: state.isOffline ? "You're offline" : "Couldn't load lessons",
            message: state.isOffline
                ? 'Open this course once while online to make its lessons available offline.'
                : state.refreshFailure!.message,
            actionLabel: 'Try again',
            onAction: () => _refresh(context),
          ),
          CourseDetailStatus.notFound => const StatusView(
            icon: Icons.search_off,
            title: 'Course not found',
            message: 'This course is no longer available.',
          ),
        },
      ),
    );
  }

  static void _refresh(BuildContext context) => context
      .read<CourseDetailBloc>()
      .add(const CourseDetailRefreshRequested());

  static void _showNotice(BuildContext context, CourseDetailState state) {
    final message = switch (state.notice) {
      CourseDetailNotice.savedOffline =>
        "Saved on this device. It will sync when you're back online.",
      CourseDetailNotice.completionFailed =>
        "Couldn't save your progress. Please try again.",
      null => null,
    };
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LessonList extends StatelessWidget {
  const _LessonList({required this.state});

  final CourseDetailState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CourseDetailBloc>();
    final detail = state.detail!;
    final lessons = detail.lessons;
    final failure = state.refreshFailure;

    return RefreshIndicator(
      onRefresh: () {
        bloc.add(const CourseDetailRefreshRequested());
        return bloc.stream.firstWhere((s) => !s.isRefreshing);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CourseProgressHeader(detail: detail),
          ),
          if (failure != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: InfoBanner(
                icon: state.isOffline ? Icons.cloud_off : Icons.error_outline,
                message: state.isOffline
                    ? "You're offline. Showing saved lessons."
                    : "Couldn't refresh: ${failure.message}",
                actionLabel: 'Retry',
                onAction: () => bloc.add(const CourseDetailRefreshRequested()),
              ),
            ),
          const SizedBox(height: 8),
          for (final lesson in lessons)
            LessonTile(
              lesson: lesson,
              isSaving: state.completingLessonIds.contains(lesson.id),
              onMarkCompleted: () =>
                  bloc.add(LessonCompletionRequested(lesson.id)),
            ),
        ],
      ),
    );
  }
}
