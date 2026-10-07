import 'package:flutter/material.dart';

import '../../../../core/utils/progress_bar.dart';
import '../../domain/model/course_detail.dart';

class CourseProgressHeader extends StatelessWidget {
  const CourseProgressHeader({super.key, required this.detail});

  final CourseDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = detail.course;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(course.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          course.instructor,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Text('Current progress', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        ProgressBar(percent: course.progress),
        const SizedBox(height: 4),
        Text(
          '${detail.completedCount} of ${detail.lessons.length} lessons completed',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
