// Caique Vasconcelos Naimi - 25004208
// Data: 28/10/2026
// Descrição: Alertas de exemplo (iguais aos do protótipo) usados só nos testes
// e na prévia. Não são usados pelo app.

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
