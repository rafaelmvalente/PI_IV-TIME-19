// Caique Vasconcelos Naimi - 25004208
// Data: 03/11/2026
// Descrição: Testes do AlertaService com os alertas de exemplo em memória.

import 'package:app/models/alerta.dart';
import 'package:app/services/alerta_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const servico = AlertaService();

  test('listar traz só alertas de hoje em diante, do mais próximo', () async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    final alertas = await servico.listar('p1');

    expect(alertas, isNotEmpty);
    expect(alertas.every((a) => !a.previstoPara.isBefore(hoje)), isTrue);
    for (var i = 1; i < alertas.length; i++) {
      expect(
        alertas[i - 1].previstoPara.isAfter(alertas[i].previstoPara),
        isFalse,
      );
    }
  });

  test('listar filtra alertas por tipo', () async {
    final alertas = await servico.listar('p1', tipo: TipoAlerta.geada);

    expect(alertas, isNotEmpty);
    expect(alertas.every((a) => a.tipo == TipoAlerta.geada), isTrue);
  });

  test('histórico traz também os passados, do mais recente', () async {
    final historico = await servico.listarHistorico('p1');
    final proximos = await servico.listar('p1');

    expect(historico.length, greaterThan(proximos.length));
    for (var i = 1; i < historico.length; i++) {
      expect(
        historico[i - 1].previstoPara.isBefore(historico[i].previstoPara),
        isFalse,
      );
    }
  });

  test('atualizarStatus muda o status e o histórico já mostra', () async {
    final atualizado = await servico.atualizarStatus(
      '1',
      StatusAlerta.resolvido,
    );

    expect(atualizado.status, StatusAlerta.resolvido);
    final historico = await servico.listarHistorico('p1');
    expect(
      historico.firstWhere((a) => a.id == '1').status,
      StatusAlerta.resolvido,
    );
  });

  test('atualizarStatus de alerta inexistente dá erro', () {
    expect(
      servico.atualizarStatus('nao-existe', StatusAlerta.resolvido),
      throwsStateError,
    );
  });
}
