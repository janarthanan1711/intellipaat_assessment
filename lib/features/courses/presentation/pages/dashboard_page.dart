import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/app_arguments.dart';
import '../../../../common/app_routes.dart';
import '../../../../core/utils/info_banner.dart';
import '../../../../core/utils/status_view.dart';
import '../../application/dashboard_bloc.dart';
import '../../domain/model/course.dart';
import '../widgets/course_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<DashboardBloc>().add(
              const DashboardLogoutRequested(),
            ),
          ),
        ],
      ),
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listenWhen: (previous, current) =>
            !previous.loggedOut && current.loggedOut,
        listener: (context, _) => Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false),
        buildWhen: (previous, current) =>
            previous.loggedOut == current.loggedOut,
        builder: (context, state) => switch (state.status) {
          DashboardStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          DashboardStatus.content => _CourseList(state: state),
          DashboardStatus.empty => StatusView(
            icon: Icons.school_outlined,
            title: 'No courses yet',
            message: 'Courses you enrol in will appear here.',
            actionLabel: 'Refresh',
            onAction: () => _refresh(context),
          ),
          DashboardStatus.failure => StatusView(
            icon: state.isOffline ? Icons.cloud_off : Icons.error_outline,
            title: state.isOffline ? "You're offline" : "Couldn't load courses",
            message: state.isOffline
                ? 'Connect to the internet to load your courses for the first time.'
                : state.refreshFailure!.message,
            actionLabel: 'Try again',
            onAction: () => _refresh(context),
          ),
        },
      ),
    );
  }

  static void _refresh(BuildContext context) =>
      context.read<DashboardBloc>().add(const DashboardRefreshRequested());
}

class _CourseList extends StatelessWidget {
  const _CourseList({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DashboardBloc>();
    final failure = state.refreshFailure;
    final courses = state.courses;

    return RefreshIndicator(
      onRefresh: () {
        bloc.add(const DashboardRefreshRequested());
        return bloc.stream.firstWhere((s) => !s.isRefreshing);
      },
      child: ListView.separated(
        // Keeps pull-to-refresh working when the list is shorter than the screen.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: courses.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            if (failure == null) return const SizedBox.shrink();
            return InfoBanner(
              icon: state.isOffline ? Icons.cloud_off : Icons.error_outline,
              message: state.isOffline
                  ? "You're offline. Showing saved courses."
                  : "Couldn't refresh: ${failure.message}",
              actionLabel: 'Retry',
              onAction: () => bloc.add(const DashboardRefreshRequested()),
            );
          }
          final course = courses[index - 1];
          return CourseCard(
            course: course,
            onOpen: () => _openCourse(context, course),
          );
        },
      ),
    );
  }

  void _openCourse(BuildContext context, Course course) {
    Navigator.of(context).pushNamed(
      AppRoutes.courseDetail,
      arguments: CourseDetailArguments(
        courseId: course.id,
        courseTitle: course.title,
      ),
    );
  }
}
