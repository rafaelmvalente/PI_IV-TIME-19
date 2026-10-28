// Estrutura criada em 28/10/26 — implementação pendente (responsável: a definir)
// Descrição: Endereço do backend consumido pelo app (backend ainda a definir).

abstract final class ApiConfig {
  // TODO(P019): definir a URL por ambiente (ex.: --dart-define=API_URL=...).
  // Não há valor padrão de propósito: o backend ainda não foi definido.
  static const String baseUrl = String.fromEnvironment('API_URL');
}
