/// Endereço do servidor (Dart Frog).
/// Para rodar no emulador Android, use:
///   flutter run --dart-define=API_URL=http://10.0.2.2:8080
class ApiConfig {
  ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );
}
