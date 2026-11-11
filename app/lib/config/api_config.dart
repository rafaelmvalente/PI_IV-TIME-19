// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Define o endereço base da API do ClimAlerta por ambiente.

abstract final class ApiConfig {
  // Configure com --dart-define=API_URL=http://host:3000/api/v1.
  static const String baseUrl = String.fromEnvironment('API_URL');
}
