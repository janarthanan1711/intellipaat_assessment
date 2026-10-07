part of 'login_bloc.dart';

enum LoginStatus { idle, submitting, success, failure }

final class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.showValidation = false,
    this.status = LoginStatus.idle,
    this.failure,
  });

  final String email;
  final String password;
  final bool showValidation;
  final LoginStatus status;

  /// Set only while [status] is [LoginStatus.failure].
  final Failure? failure;

  String? get emailError => showValidation ? AppValidators.email(email) : null;

  String? get passwordError =>
      showValidation ? AppValidators.password(password) : null;

  bool get isFormValid =>
      AppValidators.email(email) == null &&
      AppValidators.password(password) == null;

  bool get isSubmitting => status == LoginStatus.submitting;

  /// [failure] is not carried over: every new state clears it unless passed.
  LoginState copyWith({
    String? email,
    String? password,
    bool? showValidation,
    LoginStatus? status,
    Failure? failure,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      showValidation: showValidation ?? this.showValidation,
      status: status ?? this.status,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [email, password, showValidation, status, failure];
}
