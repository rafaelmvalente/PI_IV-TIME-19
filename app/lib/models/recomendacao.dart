// Caique Vasconcelos Naimi - 25004208
// Data: 28/10/2026
// Descrição: Ação prática sugerida para um alerta (ex.: "Proteja as mudas"),
// com dicas extras em linguagem simples.

class Recomendacao {
  const Recomendacao({
    required this.acao,
    this.detalhe = '',
    this.dicas = const [],
  });

  final String acao;
  // Como fazer a ação (ex.: "Cubra as plantas mais sensíveis com lonas...").
  final String detalhe;
  final List<String> dicas;

  // TODO(P022): fromJson/toJson conforme o contrato da API (P010).
}
