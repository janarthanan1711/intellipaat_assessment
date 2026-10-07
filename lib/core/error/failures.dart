import 'package:equatable/equatable.dart';

/// Domain-level error. Data sources translate their exceptions into one of
/// these so nothing above the repository ever sees Dio or sqflite types.
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// User-presentable description.
  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Your session has expired. Please log in again.',
  ]);
}

final class ParsingFailure extends Failure {
  const ParsingFailure([
    super.message = 'Received unexpected data from the server.',
  ]);
}

final class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Could not access saved data on this device.',
  ]);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
