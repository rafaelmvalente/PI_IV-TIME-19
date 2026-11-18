// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 18/11/2026
// Descrição: Testa o botão "Ouvir alerta" da tela de detalhe (issue #17): só
// aparece com a preferência de voz ativa e lê o alerta ao ser tocado.

import 'package:app/models/alerta.dart';
import 'package:app/models/preferencias_alerta.dart';
import 'package:app/models/recomendacao.dart';
import 'package:app/screens/detalhe_alerta_screen.dart';
import 'package:app/services/voz_service.dart';
import 'package:app/session/sessao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MotorFalso implements MotorDeVoz {
  final falas = <String>[];

  @override
  Future<void> configurar(String idioma) async {}

  @override
  Future<void> falar(String texto) async => falas.add(texto);

  @override
  Future<void> parar() async {}
}

final _alerta = Alerta(
  id: 'a1',
  propriedadeId: 'p1',
  tipo: TipoAlerta.geada,
  nivel: NivelRisco.alto,
  previstoPara: DateTime.utc(2026, 11, 12, 12),
  descricao: 'A temperatura mínima prevista é de 1°C.',
  status: StatusAlerta.emAndamento,
  recomendacao: const Recomendacao(
    acao: 'Proteja as plantas mais sensíveis',
    detalhe: 'Cubra as plantas com lona.',
  ),
);

Future<void> _abrir(WidgetTester tester, Widget tela) async {
  // Tela alta para o botão ficar visível sem precisar rolar.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: tela));
}

Widget _comSessao({required bool voz, required VozService servico}) {
  final sessao = SessaoController()
    ..entrar(
      login: 'antonio@exemplo.com',
      preferencias: PreferenciasAlerta(texto: true, voz: voz, sms: false),
    );
  return SessaoScope(
    controller: sessao,
    child: DetalheAlertaScreen(alerta: _alerta, voz: servico),
  );
}

void main() {
  testWidgets('não mostra o botão quando a voz está desligada', (tester) async {
    final servico = VozService(motor: _MotorFalso());
    await _abrir(tester, _comSessao(voz: false, servico: servico));

    expect(find.text('Ouvir alerta'), findsNothing);
  });

  testWidgets('sem sessão (tela isolada) também não mostra o botão', (
    tester,
  ) async {
    await _abrir(tester, DetalheAlertaScreen(alerta: _alerta));

    expect(find.text('Ouvir alerta'), findsNothing);
  });

  testWidgets('com a voz ligada, o botão lê o alerta', (tester) async {
    final motor = _MotorFalso();
    final servico = VozService(
      motor: motor,
      agora: () => DateTime(2026, 11, 11, 10),
    );
    await _abrir(tester, _comSessao(voz: true, servico: servico));

    await tester.tap(find.text('Ouvir alerta'));
    await tester.pumpAndSettle();

    expect(motor.falas, hasLength(1));
    expect(motor.falas.first, contains('risco alto de geada'));
    expect(motor.falas.first, contains('Proteja as plantas mais sensíveis'));
    // Terminou de falar: o botão volta a oferecer "Ouvir alerta".
    expect(find.text('Ouvir alerta'), findsOneWidget);
  });
}
