import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/app_validators.dart';
import '../../../core/error/failures.dart';
import '../domain/usecases/auth_usecase.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this._authUsecase) : super(const LoginState()) {
    // Editing a field dismisses a previous login error.
    on<LoginEmailChanged>(
      (event, emit) =>
          emit(state.copyWith(email: event.email, status: LoginStatus.idle)),
    );
    on<LoginPasswordChanged>(
      (event, emit) => emit(
        state.copyWith(password: event.password, status: LoginStatus.idle),
      ),
    );
    on<LoginSubmitted>(_onSubmitted);
  }

  final AuthUsecase _authUsecase;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state.status == LoginStatus.submitting) return;

    // From the first attempt on, field errors are shown and stay live while typing.
    emit(state.copyWith(showValidation: true));
    if (!state.isFormValid) return;

    emit(state.copyWith(status: LoginStatus.submitting));
    final result = await _authUsecase.login(
      email: state.email,
      password: state.password,
    );
    emit(
      result.fold(
        (failure) =>
            state.copyWith(status: LoginStatus.failure, failure: failure),
        (_) => state.copyWith(status: LoginStatus.success),
      ),
    );
  }
}
