// Valores inyectados en build con --dart-define=BASE_URL=http://...
// Si no se pasan, usa el valor local por defecto para desarrollo.
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://web-production-8e7ef.up.railway.app',
  );

  static const bool isProduction = bool.fromEnvironment('IS_PRODUCTION');
}
