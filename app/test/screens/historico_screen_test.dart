// Caique Vasconcelos Naimi - 25004208
// Data: 03/11/2026
// Descrição: Testes de widget da tela de Histórico: agrupamento por mês,
// status, filtro por tipo, estados de vazio/erro e abertura do detalhe.

import 'package:app/models/alerta.dart';
import 'package:app/models/recomendacao.dart';
import 'package:app/screens/detalhe_alerta_screen.dart';
import 'package:app/screens/historico_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Alerta _alerta(String id, TipoAlerta tipo, DateTime data, StatusAlerta status) {
  return Alerta(
    id: id,
    propriedadeId: 'p1',
    tipo: tipo,
    nivel: NivelRisco.alto,
    previstoPara: data,
    descricao: 'Descrição $id',
    status: status,
    recomendacao: const Recomendacao(acao: 'Proteja as mudas'),
  );
}

final _historico = [
  _alerta('1', TipoAlerta.geada, DateTime(2026, 11, 2, 6),
      StatusAlerta.emAndamento),
  _alerta('2', TipoAlerta.chuvaForte, DateTime(2026, 11, 1, 14),
      StatusAlerta.acaoRealizada),
  _alerta('3', TipoAlerta.seca, DateTime(2026, 10, 5, 10),
      StatusAlerta.resolvido),
];

void main() {
  Widget tela(Future<List<Alerta>> Function() carregar) =>
      MaterialApp(home: HistoricoScreen(carregarHistorico: carregar));

  testWidgets('agrupa por mês e mostra o status de cada alerta',
      (tester) async {
    await tester.pumpWidget(tela(() async => _historico));
    await tester.pumpAndSettle();

    expect(find.text('Novembro de 2026'), findsOneWidget);
    expect(find.text('Outubro de 2026'), findsOneWidget);
    expect(find.text('Em andamento'), findsOneWidget);
    expect(find.text('Ação realizada'), findsOneWidget);
    expect(find.text('Resolvido'), findsOneWidget);

    // O mês vem antes dos alertas dele.
    final novembro = tester.getTopLeft(find.text('Novembro de 2026')).dy;
    final outubro = tester.getTopLeft(find.text('Outubro de 2026')).dy;
    final seca = tester.getTopLeft(find.text('Seca prolongada')).dy;
    expect(novembro, lessThan(outubro));
    expect(outubro, lessThan(seca));
  });

  testWidgets('filtro "Seca" esconde os outros tipos e meses', (tester) async {
    await tester.pumpWidget(tela(() async => _historico));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seca'));
    await tester.pumpAndSettle();

    expect(find.text('Seca prolongada'), findsOneWidget);
    expect(find.text('Risco de geada'), findsNothing);
    expect(find.text('Novembro de 2026'), findsNothing);
  });

  testWidgets('mostra vazio quando não há histórico', (tester) async {
    await tester.pumpWidget(tela(() async => []));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum alerta no histórico ainda.'), findsOneWidget);
  });

  testWidgets('mostra erro e tenta de novo', (tester) async {
    var tentativas = 0;
    await tester.pumpWidget(
      tela(() {
        tentativas++;
        if (tentativas == 1) throw Exception('sem conexão');
        return Future.value(_historico);
      }),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Não foi possível carregar'), findsOneWidget);

    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('Risco de geada'), findsOneWidget);
  });

  testWidgets('abre o detalhe e recarrega ao voltar', (tester) async {
    var carregamentos = 0;
    await tester.pumpWidget(
      tela(() async {
        carregamentos++;
        return _historico;
      }),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Risco de geada'));
    await tester.pumpAndSettle();
    expect(find.byType(DetalheAlertaScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(HistoricoScreen), findsOneWidget);
    expect(carregamentos, 2);
  });
}
