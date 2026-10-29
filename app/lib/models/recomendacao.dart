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

  // Usado pelo cache offline. Os nomes dos campos podem mudar quando o
  // contrato da API for definido (P010).
  factory Recomendacao.fromJson(Map<String, dynamic> json) {
    return Recomendacao(
      acao: json['acao'] as String,
      detalhe: json['detalhe'] as String? ?? '',
      dicas: List<String>.from(json['dicas'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'acao': acao, 'detalhe': detalhe, 'dicas': dicas};
  }
}
