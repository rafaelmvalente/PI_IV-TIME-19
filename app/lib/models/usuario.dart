// Descrição: Produtor rural dono da conta, conforme o contrato da API.
// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Implementa a conversão JSON do usuário e suas preferências.

import 'preferencias_alerta.dart';

class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    this.email,
    this.telefone,
    this.preferencias = PreferenciasAlerta.padrao,
  });

  final String id;
  final String nome;
  final String? email;
  final String? telefone;
  final PreferenciasAlerta preferencias;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String?,
      telefone: json['telefone'] as String?,
      preferencias: PreferenciasAlerta.fromJson(
        json['preferencias'] as Map<String, dynamic>? ??
            const <String, dynamic>{'texto': true, 'voz': false, 'sms': false},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'preferencias': preferencias.toJson(),
    };
  }
}
