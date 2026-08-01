abstract final class ApiConfig {
  /// API locale sous XAMPP/Apache.
  ///
  /// Pour surcharger au lancement :
  /// flutter run -d windows --dart-define=API_BASE_URL=https://api.exemple.gn
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'http://127.0.0.1/sigp_plus/backend_php/public',
  );

  static const Duration timeout = Duration(seconds: 30);
}
