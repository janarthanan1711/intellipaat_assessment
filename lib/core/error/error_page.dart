import 'package:flutter/material.dart';

import '../utils/status_view.dart';

/// Fallback for unknown routes or routes opened with invalid arguments.
class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: StatusView(
        icon: Icons.error_outline,
        title: 'Page not found',
        message: 'This page is unavailable.',
        actionLabel: 'Go back',
        onAction: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
