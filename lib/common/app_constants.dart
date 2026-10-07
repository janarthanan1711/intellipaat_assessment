abstract final class AppConstants {
  static const appName = 'Learning Dashboard';

  static const baseUrl = 'https://api.learning-dashboard.example/v1';
  static const networkTimeout = Duration(seconds: 30);

  /// Serve API calls from `assets/mock/` instead of the network. The mock
  /// still goes through the full Dio pipeline and fails when the device is
  /// offline, so offline behaviour is exercised for real.
  static const useMockApi = true;

  /// `normal`, `empty` or `error` — pick with
  /// `flutter run --dart-define=MOCK_SCENARIO=empty` to see each dashboard state.
  static const mockScenario = String.fromEnvironment(
    'MOCK_SCENARIO',
    defaultValue: 'normal',
  );

  /// Credentials accepted by the mock login endpoint.
  static const demoEmail = 'demo@learner.com';
  static const demoPassword = 'password123';
}
