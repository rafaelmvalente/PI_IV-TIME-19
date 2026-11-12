// Caique Vasconcelos Naimi - 25004208
// Data: 03/11/2026
// Descrição: Testes de widget da navegação do dashboard: barra inferior,
// sino, "Ver todos", avatar, alerta em destaque e próximos alertas.

import 'package:app/data/alertas_exemplo.dart';
import 'package:app/models/clima.dart';
import 'package:app/models/coordenada.dart';
import 'package:app/models/propriedade.dart';
import 'package:app/screens/alertas_screen.dart';
import 'package:app/screens/dashboard_screen.dart';
import 'package:app/screens/detalhe_alerta_screen.dart';
import 'package:app/screens/historico_screen.dart';
import 'package:app/screens/perfil_screen.dart';
import 'package:app/session/sessao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<SessaoController> _abrir(WidgetTester tester) async {
  // Tela alta para o dashboard inteiro caber sem rolar.
  tester.view.physicalSize = const Size(430, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final sessao = SessaoController();
  await tester.pumpWidget(
    SessaoScope(
      controller: sessao,
      child: MaterialApp(
        home: DashboardScreen(
          propriedade: const Propriedade(
            id: 'p1',
            nome: 'Fazenda Boa Vista',
            cultivo: TipoCultivo.soja,
            localizacao: Coordenada(latitude: -23.5, longitude: -46.6),
          ),
          carregarAlertas: (_) async => alertasDeExemplo(DateTime.now()),
          carregarHistorico: (_) async => historicoDeExemplo(DateTime.now()),
          carregarPrevisao: (_) async => PrevisaoClimatica.fromJson({
            'current': {'temperatura': 24, 'descricao': 'Céu limpo'},
            'daily': [
              {
                'date': '2026-11-11',
                'maxima': 28,
                'minima': 16,
                'precipitation': 0,
              },
            ],
          }),
          atualizarStatusAlerta: (alerta, status) async =>
              alerta.copyWith(status: status),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return sessao;
}

// Toca no item da barra inferior (o texto também pode aparecer no título da aba).
Future<void> _tocarAba(WidgetTester tester, String rotulo) async {
  await tester.tap(
    find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text(rotulo),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('barra inferior troca entre as quatro abas', (tester) async {
    await _abrir(tester);

    await _tocarAba(tester, 'Alertas');
    expect(find.byType(AlertasScreen), findsOneWidget);

    await _tocarAba(tester, 'Histórico');
    expect(find.byType(HistoricoScreen), findsOneWidget);
    expect(find.byType(AlertasScreen), findsNothing);

    await _tocarAba(tester, 'Perfil');
    expect(find.byType(PerfilScreen), findsOneWidget);

    await _tocarAba(tester, 'Início');
    expect(find.text('Próximos alertas'), findsOneWidget);
    expect(find.byType(PerfilScreen), findsNothing);
  });

  testWidgets('sino e "Ver todos" abrem a aba Alertas', (tester) async {
    await _abrir(tester);

    await tester.tap(find.byTooltip('Alertas'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertasScreen), findsOneWidget);

    await _tocarAba(tester, 'Início');
    await tester.tap(find.text('Ver todos'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertasScreen), findsOneWidget);
  });

  testWidgets('avatar abre a aba Perfil', (tester) async {
    await _abrir(tester);

    await tester.tap(find.bySemanticsLabel('Perfil').first);
    await tester.pumpAndSettle();

    expect(find.byType(PerfilScreen), findsOneWidget);
  });

  testWidgets('destaque e próximos alertas abrem o detalhe', (tester) async {
    await _abrir(tester);

    expect(find.text('Alerta de geada'), findsOneWidget);
    await tester.tap(find.text('Alerta de geada'));
    await tester.pumpAndSettle();
    expect(find.byType(DetalheAlertaScreen), findsOneWidget);
    expect(find.text('Risco de geada'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chuva forte'));
    await tester.pumpAndSettle();
    expect(find.text('Risco de chuva forte'), findsOneWidget);
  });

  testWidgets('mostra o nome da propriedade guardada na sessão', (
    tester,
  ) async {
    final sessao = await _abrir(tester);
    expect(find.text('Fazenda Boa Vista'), findsOneWidget);

    sessao.definirPropriedade(
      const Propriedade(
        nome: 'Sítio Esperança',
        cultivo: TipoCultivo.cafe,
        localizacao: Coordenada(latitude: -22.9, longitude: -47.0),
      ),
    );
    await tester.pump();

    expect(find.text('Sítio Esperança'), findsOneWidget);
  });
}
