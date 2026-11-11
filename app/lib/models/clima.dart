// Estrutura criada em 28/10/26 — implementação pendente (responsável: a definir)
// Descrição: Clima do dia da propriedade, exibido no dashboard
// (temperatura atual, máxima, mínima e descrição).

class ClimaHoje {
  const ClimaHoje({
    required this.temperatura,
    required this.maxima,
    required this.minima,
    required this.descricao,
  });

  final double temperatura;
  final double maxima;
  final double minima;
  final String descricao;

  // Usado pelo cache offline. Os nomes dos campos podem mudar quando o
  // contrato da API for definido (P010).
  factory ClimaHoje.fromJson(Map<String, dynamic> json) {
    return ClimaHoje(
      temperatura: (json['temperatura'] as num).toDouble(),
      maxima: (json['maxima'] as num).toDouble(),
      minima: (json['minima'] as num).toDouble(),
      descricao: json['descricao'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperatura': temperatura,
      'maxima': maxima,
      'minima': minima,
      'descricao': descricao,
    };
  }
}
