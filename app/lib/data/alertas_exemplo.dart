// Caique Vasconcelos Naimi - 25004208
// Data: 28/10/2026
// Descrição: Alertas de exemplo (iguais aos do protótipo). O AlertaService usa
// estes dados enquanto o backend não existe (P010); os testes e a prévia
// também usam.

import 'package:app/models/alerta.dart';
import 'package:app/models/recomendacao.dart';

List<Alerta> alertasDeExemplo(DateTime agora) {
  final hoje = DateTime(agora.year, agora.month, agora.day);

  return [
    Alerta(
      id: '1',
      propriedadeId: 'p1',
      tipo: TipoAlerta.geada,
      nivel: NivelRisco.alto,
      previstoPara: hoje.add(const Duration(hours: 6)),
      descricao: 'Há alta probabilidade de geada na sua região nas próximas '
          'horas. A temperatura pode cair para 2°C.',
      status: StatusAlerta.emAndamento,
      recomendacao: const Recomendacao(
        acao: 'Proteja as mudas',
        detalhe: 'Cubra as plantas mais sensíveis com lonas ou plástico '
            'agrícola para evitar danos causados pela geada.',
        dicas: [
          'Use lonas transparentes, se possível.',
          'Evite irrigar no fim do dia.',
        ],
      ),
    ),
    Alerta(
      id: '2',
      propriedadeId: 'p1',
      tipo: TipoAlerta.chuvaForte,
      nivel: NivelRisco.medio,
      previstoPara: hoje.add(const Duration(days: 1, hours: 14)),
      descricao: 'Previsão de chuva forte amanhã à tarde, com risco de '
          'alagamento nas partes baixas da plantação.',
      status: StatusAlerta.emAndamento,
      recomendacao: const Recomendacao(
        acao: 'Limpe as valetas',
        detalhe: 'Desobstrua as valetas e canais para a água escoar.',
      ),
    ),
    Alerta(
      id: '3',
      propriedadeId: 'p1',
      tipo: TipoAlerta.seca,
      nivel: NivelRisco.alto,
      previstoPara: hoje.add(const Duration(days: 3, hours: 10)),
      descricao: 'Vários dias sem chuva e calor forte previstos.',
      status: StatusAlerta.emAndamento,
      recomendacao: const Recomendacao(acao: 'Economize água'),
    ),
  ];
}

// Alertas que já passaram, com status variados, para a tela de Histórico ter
// meses diferentes para agrupar.
List<Alerta> historicoDeExemplo(DateTime agora) {
  final hoje = DateTime(agora.year, agora.month, agora.day);

  return [
    Alerta(
      id: '4',
      propriedadeId: 'p1',
      tipo: TipoAlerta.chuvaForte,
      nivel: NivelRisco.alto,
      previstoPara: hoje.subtract(const Duration(days: 4, hours: 7)),
      descricao: 'Chuva forte com rajadas de vento durante a tarde.',
      status: StatusAlerta.acaoRealizada,
      recomendacao: const Recomendacao(
        acao: 'Limpe as valetas',
        detalhe: 'Desobstrua as valetas e canais para a água escoar.',
      ),
    ),
    Alerta(
      id: '5',
      propriedadeId: 'p1',
      tipo: TipoAlerta.geada,
      nivel: NivelRisco.medio,
      previstoPara: hoje.subtract(const Duration(days: 35, hours: 18)),
      descricao: 'A temperatura caiu para 4°C durante a madrugada.',
      status: StatusAlerta.resolvido,
      recomendacao: const Recomendacao(acao: 'Proteja as mudas'),
    ),
    Alerta(
      id: '6',
      propriedadeId: 'p1',
      tipo: TipoAlerta.seca,
      nivel: NivelRisco.alto,
      previstoPara: hoje.subtract(const Duration(days: 64, hours: 14)),
      descricao: 'Duas semanas sem chuva e calor acima de 32°C.',
      status: StatusAlerta.resolvido,
      recomendacao: const Recomendacao(acao: 'Economize água'),
    ),
  ];
}
