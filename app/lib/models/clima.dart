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

  // TODO(P022): fromJson conforme o contrato da API (P010).
}
