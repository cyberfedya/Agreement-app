class AppConfig {
  const AppConfig._();

  static const String appName = 'EasyAgree';

  /// Falls back to the current demo tunnel rather than a placeholder that
  /// can never resolve - a build produced without `--dart-define=API_BASE_URL=...`
  /// (easy to forget when handing a demo APK to someone else) still works
  /// out of the box instead of silently failing every request.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://certified-nuttiness-anteater.ngrok-free.dev',
  );
}
