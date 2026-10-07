import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learning_dashboard/core/error/failures.dart';
import 'package:learning_dashboard/features/auth/application/login_bloc.dart';

import 'fakes.dart';

void main() {
  const invalidCredentials = UnauthorizedFailure('Invalid email or password.');

  late FakeAuthUsecase usecase;

  blocTest<LoginBloc, LoginState>(
    'invalid input shows field errors and never calls the API',
    setUp: () => usecase = FakeAuthUsecase(const Right(unit)),
    build: () => LoginBloc(usecase),
    act: (bloc) => bloc
      ..add(const LoginEmailChanged('not-an-email'))
      ..add(const LoginPasswordChanged('123'))
      ..add(const LoginSubmitted()),
    skip: 2,
    expect: () => [
      isA<LoginState>()
          .having(
            (s) => s.emailError,
            'emailError',
            'Enter a valid email address.',
          )
          .having((s) => s.passwordError, 'passwordError', isNotNull)
          .having((s) => s.status, 'status', LoginStatus.idle),
    ],
    verify: (_) => expect(usecase.loginCalls, 0),
  );

  blocTest<LoginBloc, LoginState>(
    'valid credentials go through loading to success',
    setUp: () => usecase = FakeAuthUsecase(const Right(unit)),
    build: () => LoginBloc(usecase),
    seed: () =>
        const LoginState(email: 'demo@learner.com', password: 'password123'),
    act: (bloc) => bloc.add(const LoginSubmitted()),
    expect: () => [
      const LoginState(
        email: 'demo@learner.com',
        password: 'password123',
        showValidation: true,
      ),
      const LoginState(
        email: 'demo@learner.com',
        password: 'password123',
        showValidation: true,
        status: LoginStatus.submitting,
      ),
      const LoginState(
        email: 'demo@learner.com',
        password: 'password123',
        showValidation: true,
        status: LoginStatus.success,
      ),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'a rejected login surfaces the failure, and editing a field clears it',
    setUp: () => usecase = FakeAuthUsecase(const Left(invalidCredentials)),
    build: () => LoginBloc(usecase),
    seed: () =>
        const LoginState(email: 'demo@learner.com', password: 'wrongpass'),
    // The edit happens after the response, as in the UI (fields are disabled
    // while submitting).
    act: (bloc) async {
      bloc.add(const LoginSubmitted());
      await bloc.stream.firstWhere((s) => s.status == LoginStatus.failure);
      bloc.add(const LoginPasswordChanged('wrongpass2'));
    },
    skip: 2,
    expect: () => [
      isA<LoginState>()
          .having((s) => s.status, 'status', LoginStatus.failure)
          .having((s) => s.failure, 'failure', invalidCredentials),
      isA<LoginState>()
          .having((s) => s.status, 'status', LoginStatus.idle)
          .having((s) => s.failure, 'failure', isNull),
    ],
  );
}
