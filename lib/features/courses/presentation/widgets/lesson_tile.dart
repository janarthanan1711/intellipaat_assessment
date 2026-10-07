import 'package:flutter/material.dart';

import '../../../../common/app_colors.dart';
import '../../domain/model/lesson.dart';

class LessonTile extends StatelessWidget {
  const LessonTile({
    super.key,
    required this.lesson,
    required this.isSaving,
    required this.onMarkCompleted,
  });

  final Lesson lesson;

  /// The completion is being saved/synced; prevents double taps.
  final bool isSaving;
  final VoidCallback onMarkCompleted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final completed = lesson.isCompleted;

    return ListTile(
      leading: Icon(
        completed ? Icons.check_circle : Icons.radio_button_unchecked,
        color: completed ? AppColors.success : colors.onSurfaceVariant,
      ),
      title: Text(lesson.title),
      subtitle: Text(completed ? 'Completed' : 'Pending'),
      trailing: completed
          ? null
          : isSaving
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: onMarkCompleted,
              child: const Text('Mark complete'),
            ),
    );
  }
}
