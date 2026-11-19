// Caique Vasconcelos Naimi - 25004208
// Data: 28/10/2026
// Descrição: Testes de serialização dos modelos de alerta.

import 'package:app/models/alerta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Alerta.fromJson converte a resposta da API', () {
    // Mesmo formato do serializeAlert do backend (routes/alerts.js).
    final json = {
      'id': 'a1',
      'propriedadeId': 'p1',
      'tipo': 'geada',
      'nivel': 'alto',
      'previstoPara': '2026-11-24T12:00:00.000Z',
      'descricao': 'A temperatura mínima prevista é de 0°C.',
      'status': 'emAndamento',
      'recomendacao': {
        'acao': 'Proteja as plantas mais sensíveis',
        'detalhe': 'Cubra as plantas com lona.',
        'dicas': ['Evite irrigar no fim do dia.'],
      },
    };

    final alerta = Alerta.fromJson(json);

    expect(alerta.tipo, TipoAlerta.geada);
    expect(alerta.nivel, NivelRisco.alto);
    expect(alerta.status, StatusAlerta.emAndamento);
    expect(alerta.previstoPara, DateTime.utc(2026, 11, 24, 12));
    expect(alerta.recomendacao.acao, 'Proteja as plantas mais sensíveis');
    expect(Alerta.fromJson(alerta.toJson()).toJson(), alerta.toJson());
  });
}
