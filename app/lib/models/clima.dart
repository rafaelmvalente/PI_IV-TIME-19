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

  // Converte a representação JSON usada pelo cache offline.
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
