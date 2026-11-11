// Nome: Rafael Mendes Valente - RA: 25002875
// Dia: 11/11/2026
// Descrição: Define a URL base do backend consumida pelo aplicativo.

abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment('API_URL');
}
