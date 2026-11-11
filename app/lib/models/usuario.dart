// Nome: Rafael Mendes Valente - RA: 25002875
// Dia: 11/11/2026
// Descrição: Representa o produtor rural e os dados da conta.

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
}
