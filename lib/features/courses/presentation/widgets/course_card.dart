import 'package:flutter/material.dart';

import '../../../../core/utils/progress_bar.dart';
import '../../domain/model/course.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, required this.onOpen});

  final Course course;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(course.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(course.instructor, style: subtle),
              const SizedBox(height: 16),
              ProgressBar(percent: course.progress),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${course.lessonCount} lessons', style: subtle),
                  ),
                  FilledButton(
                    onPressed: onOpen,
                    child: Text(course.progress >= 100 ? 'Review' : 'Continue'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
