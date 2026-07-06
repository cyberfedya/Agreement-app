class AppConfig {
  const AppConfig._();

  static const String appName = 'EasyAgree';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.easyagree.local',
  );
}
