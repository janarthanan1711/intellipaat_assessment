import 'package:flutter/material.dart';

/// Password input with a show/hide toggle. Visibility is purely local UI
/// state, so it lives here rather than in the bloc.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.onChanged,
    required this.onSubmitted,
    this.enabled = true,
    this.errorText,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final bool enabled;
  final String? errorText;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: widget.enabled,
      obscureText: _obscured,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Password',
        errorText: widget.errorText,
        suffixIcon: IconButton(
          tooltip: _obscured ? 'Show password' : 'Hide password',
          icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
      onChanged: widget.onChanged,
      onSubmitted: (_) => widget.onSubmitted(),
    );
  }
}
