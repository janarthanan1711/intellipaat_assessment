class LoginResponse {
  const LoginResponse({required this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Login response has no token');
    }
    return LoginResponse(token: token);
  }

  final String token;
}
