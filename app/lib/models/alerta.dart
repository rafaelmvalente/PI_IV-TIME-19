// Caique Vasconcelos Naimi - 25004208
// Data: 28/10/2026
// Descrição: Alerta de risco climático recebido pelo produtor. Os tipos,
// níveis e status seguem o README e o relatório de ideação.

import 'recomendacao.dart';

enum TipoAlerta {
  geada('Geada'),
  seca('Seca prolongada'),
  chuvaForte('Chuva forte');

  const TipoAlerta(this.rotulo);

  final String rotulo;
}

enum NivelRisco {
  medio('Médio'),
  alto('Alto');

  const NivelRisco(this.rotulo);

  final String rotulo;
}

enum StatusAlerta {
  emAndamento('Em andamento'),
  acaoRealizada('Ação realizada'),
  resolvido('Resolvido');

  const StatusAlerta(this.rotulo);

  final String rotulo;
}

class Alerta {
  const Alerta({
    required this.id,
    required this.propriedadeId,
    required this.tipo,
    required this.nivel,
    required this.previstoPara,
    required this.descricao,
    required this.status,
    required this.recomendacao,
  });

  final String id;
  final String propriedadeId;
  final TipoAlerta tipo;
  final NivelRisco nivel;
  final DateTime previstoPara;
  // Explicação do risco em linguagem simples (ex.: "A temperatura pode cair para 2°C").
  final String descricao;
  final StatusAlerta status;
  final Recomendacao recomendacao;

  // Usado pelo cache offline. Os enums são gravados pelo nome (ex.: "geada")
  // e a data no formato ISO 8601. Os nomes dos campos podem mudar quando o
  // contrato da API for definido (P010).
  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: json['id'] as String,
      propriedadeId: json['propriedadeId'] as String,
      tipo: TipoAlerta.values.byName(json['tipo'] as String),
      nivel: NivelRisco.values.byName(json['nivel'] as String),
      previstoPara: DateTime.parse(json['previstoPara'] as String),
      descricao: json['descricao'] as String,
      status: StatusAlerta.values.byName(json['status'] as String),
      recomendacao: Recomendacao.fromJson(
        json['recomendacao'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propriedadeId': propriedadeId,
      'tipo': tipo.name,
      'nivel': nivel.name,
      'previstoPara': previstoPara.toIso8601String(),
      'descricao': descricao,
      'status': status.name,
      'recomendacao': recomendacao.toJson(),
    };
  }
}
