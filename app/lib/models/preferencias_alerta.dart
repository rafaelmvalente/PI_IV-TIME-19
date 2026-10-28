// Estrutura criada em 28/10/26 — implementação pendente (responsável: a definir)
// Descrição: Como o produtor quer receber os alertas: texto, voz e/ou SMS
// quando estiver sem internet (tela de Perfil / Configurações).

class PreferenciasAlerta {
  const PreferenciasAlerta({
    required this.texto,
    required this.voz,
    required this.sms,
  });

  final bool texto;
  final bool voz;
  final bool sms;

  // TODO(P022): fromJson/toJson conforme o contrato da API (P010).
}
