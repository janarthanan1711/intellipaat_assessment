import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/app_constants.dart';
import '../../../../common/app_routes.dart';
import '../../../../core/utils/info_banner.dart';
import '../../application/login_bloc.dart';
import '../widgets/password_field.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocConsumer<LoginBloc, LoginState>(
                listenWhen: (previous, current) =>
                    previous.status != current.status &&
                    current.status == LoginStatus.success,
                listener: (context, _) => Navigator.of(
                  context,
                ).pushReplacementNamed(AppRoutes.dashboard),
                builder: (context, state) => _LoginForm(state: state),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.state});

  final LoginState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LoginBloc>();
    final textTheme = Theme.of(context).textTheme;
    final failure = state.failure;
    void submit() => bloc.add(const LoginSubmitted());

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppConstants.appName, style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Log in to continue learning.', style: textTheme.bodyLarge),
          const SizedBox(height: 32),
          TextField(
            enabled: !state.isSubmitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Email',
              errorText: state.emailError,
            ),
            onChanged: (value) => bloc.add(LoginEmailChanged(value)),
          ),
          const SizedBox(height: 16),
          PasswordField(
            enabled: !state.isSubmitting,
            errorText: state.passwordError,
            onChanged: (value) => bloc.add(LoginPasswordChanged(value)),
            onSubmitted: submit,
          ),
          if (state.status == LoginStatus.failure && failure != null) ...[
            const SizedBox(height: 16),
            InfoBanner(icon: Icons.error_outline, message: failure.message),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.isSubmitting ? null : submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: state.isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Log in'),
          ),
          const SizedBox(height: 16),
          Text(
            'Demo account: ${AppConstants.demoEmail} / ${AppConstants.demoPassword}',
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
