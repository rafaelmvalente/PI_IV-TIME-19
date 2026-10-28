// Estrutura criada em 28/10/26 — implementação pendente (responsável: a definir)
// Descrição: Ação prática sugerida para um alerta (ex.: "Proteja as mudas"),
// com dicas extras em linguagem simples.

class Recomendacao {
  const Recomendacao({required this.acao, this.dicas = const []});

  final String acao;
  final List<String> dicas;

  // TODO(P022): fromJson/toJson conforme o contrato da API (P010).
}
