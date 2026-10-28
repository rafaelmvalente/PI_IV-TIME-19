// Estrutura criada em 28/10/26 — implementação pendente (responsável: a definir)
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

  // TODO(P022): fromJson/toJson conforme o contrato da API (P010).
}
