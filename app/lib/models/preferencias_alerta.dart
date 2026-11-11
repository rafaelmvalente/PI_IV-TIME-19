// Caio Ávila Marchi - 25008101
// Data: 28/10/2026
// Descrição: Como o produtor quer receber os alertas: texto, voz e/ou SMS
// quando estiver sem internet (tela de Perfil / Configurações).
// Data: 11/11/2026
// Descrição: Serializa as preferências conforme o contrato da API.

class PreferenciasAlerta {
  const PreferenciasAlerta({
    required this.texto,
    required this.voz,
    required this.sms,
  });

  /// Padrão para quem acabou de entrar: só o alerta escrito.
  static const PreferenciasAlerta padrao = PreferenciasAlerta(
    texto: true,
    voz: false,
    sms: false,
  );

  final bool texto;
  final bool voz;
  final bool sms;

  /// Pelo menos um jeito de receber alerta precisa ficar ligado.
  bool get algumAtivo => texto || voz || sms;

  PreferenciasAlerta copyWith({bool? texto, bool? voz, bool? sms}) {
    return PreferenciasAlerta(
      texto: texto ?? this.texto,
      voz: voz ?? this.voz,
      sms: sms ?? this.sms,
    );
  }

  factory PreferenciasAlerta.fromJson(Map<String, dynamic> json) {
    return PreferenciasAlerta(
      texto: json['texto'] as bool,
      voz: json['voz'] as bool,
      sms: json['sms'] as bool,
    );
  }

  Map<String, bool> toJson() {
    return {'texto': texto, 'voz': voz, 'sms': sms};
  }
}
