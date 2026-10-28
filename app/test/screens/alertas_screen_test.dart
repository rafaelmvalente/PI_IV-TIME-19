// Caique Vasconcelos Naimi - 25004208
// Data: 28/10/2026
// Descrição: Testes de widget das telas 5, 6 e 7 (lista, detalhe e
// recomendações de alertas) e da formatação da data dos alertas.

import 'package:app/models/alerta.dart';
import 'package:app/screens/alertas_screen.dart';
import 'package:app/widgets/alerta_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../preview/alertas_exemplo.dart';

void main() {
  Widget tela(Future<List<Alerta>> Function() carregar) =>
      MaterialApp(home: AlertasScreen(carregarAlertas: carregar));

  testWidgets('lista todos e o filtro "Geada" mostra só geada', (tester) async {
    await tester.pumpWidget(tela(() async => alertasDeExemplo(DateTime.now())));
    await tester.pumpAndSettle();

    expect(find.text('Risco de geada'), findsOneWidget);
    expect(find.text('Risco de chuva forte'), findsOneWidget);
    expect(find.text('Seca prolongada'), findsOneWidget);

    await tester.tap(find.text('Geada'));
    await tester.pumpAndSettle();

    expect(find.text('Risco de geada'), findsOneWidget);
    expect(find.text('Risco de chuva forte'), findsNothing);
    expect(find.text('Seca prolongada'), findsNothing);
  });

  testWidgets('mostra vazio quando não há alertas', (tester) async {
    await tester.pumpWidget(tela(() async => []));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum alerta por enquanto.'), findsOneWidget);
  });

  testWidgets('mostra erro e tenta de novo', (tester) async {
    var tentativas = 0;
    await tester.pumpWidget(tela(() {
      tentativas++;
      // Igual ao AlertaService sem backend: lança o erro na hora.
      if (tentativas == 1) throw UnimplementedError();
      return Future.value(alertasDeExemplo(DateTime.now()));
    }));
    await tester.pumpAndSettle();

    expect(find.text('Tentar de novo'), findsOneWidget);

    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('Risco de geada'), findsOneWidget);
  });

  testWidgets('detalhe abre as recomendações e "Entendi" volta', (
    tester,
  ) async {
    await tester.pumpWidget(tela(() async => alertasDeExemplo(DateTime.now())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Risco de geada'));
    await tester.pumpAndSettle();

    expect(find.text('Alto'), findsOneWidget);
    expect(find.textContaining('A temperatura pode cair para 2°C'),
        findsOneWidget);
    expect(find.textContaining('Proteja as mudas. Cubra'), findsOneWidget);

    await tester.tap(find.text('Ver outras orientações'));
    await tester.pumpAndSettle();

    expect(find.text('Dicas extras'), findsOneWidget);
    expect(find.text('Evite irrigar no fim do dia.'), findsOneWidget);

    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();

    expect(find.text('Ver outras orientações'), findsOneWidget);
  });

  testWidgets('sem backend, mudar o status mostra aviso', (tester) async {
    await tester.pumpWidget(tela(() async => alertasDeExemplo(DateTime.now())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Risco de geada'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Marcar status do alerta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolvido'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível atualizar o status agora.'),
        findsOneWidget);
    expect(find.text('Status: Em andamento'), findsOneWidget);
  });

  test('formatarQuando usa Hoje/Amanhã e o mês abreviado', () {
    final agora = DateTime(2025, 8, 22, 9);

    expect(formatarQuando(DateTime(2025, 8, 22, 6), agora: agora),
        'Hoje, 22 de ago · 06:00');
    expect(formatarQuando(DateTime(2025, 8, 23, 14), agora: agora),
        'Amanhã, 23 de ago · 14:00');
    expect(formatarQuando(DateTime(2025, 8, 25, 10, 5), agora: agora),
        '25 de ago · 10:05');
  });
}
