// Valores inyectados en build con --dart-define=BASE_URL=http://...
// Si no se pasan, usa el valor local por defecto para desarrollo.
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // emulador → localhost de la PC
  );

  static const bool isProduction = bool.fromEnvironment('IS_PRODUCTION');
}
