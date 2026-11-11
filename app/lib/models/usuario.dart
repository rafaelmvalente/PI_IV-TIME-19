// Estrutura criada em 28/10/26 — implementação pendente (responsável: a definir)
// Descrição: Produtor rural dono da conta. O telefone é necessário para o
// envio de alertas críticos por SMS.

class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    this.email,
    this.telefone,
  });

  final String id;
  final String nome;
  final String? email;
  final String? telefone;

  // TODO(P022): fromJson/toJson conforme o contrato da API (P010).
}
