import 'package:flutter/material.dart';

/// Linear progress bar with the percentage beside it.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.percent});

  /// 0–100.
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              semanticsLabel: 'Course progress',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('$percent%', style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}
