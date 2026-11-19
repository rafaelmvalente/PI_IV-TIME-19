// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 17/11/2026
// Descrição: Testa o texto da faixa que avisa, sem internet, de quando são os
// dados salvos no celular (issue #74).

import 'package:app/widgets/aviso_dados_salvos.dart';
import 'package:flutter/material.dart';
// flutter_test: test(), testWidgets(), expect() e os "find" da tela.
import 'package:flutter_test/flutter_test.dart';

void main() {
  // "Agora" fixo (17/11/2026 às 20h) para os testes darem sempre o mesmo
  // resultado, em qualquer dia em que forem rodados.
  final agora = DateTime(2026, 11, 17, 20, 0);

  // Salvo no mesmo dia: deve aparecer "de hoje" com a hora do salvamento.
  test('dados salvos hoje mostram "de hoje" e o horário', () {
    expect(
      textoDadosSalvos(DateTime(2026, 11, 17, 14, 30), agora: agora),
      'Sem internet · dados de hoje, 14:30',
    );
  });

  // Salvo no dia anterior: "de ontem". Também confere o zero à esquerda (08:05).
  test('dados salvos ontem mostram "de ontem"', () {
    expect(
      textoDadosSalvos(DateTime(2026, 11, 16, 8, 5), agora: agora),
      'Sem internet · dados de ontem, 08:05',
    );
  });

  // Salvo há mais de um dia: mostra a data no formato dia/mês.
  test('dados mais antigos mostram a data', () {
    expect(
      textoDadosSalvos(DateTime(2026, 11, 12, 9, 10), agora: agora),
      'Sem internet · dados de 12/11, 09:10',
    );
  });

  // Nunca salvou nada (null): mensagem própria em vez de dar erro.
  test('sem nada salvo avisa que não há dados', () {
    expect(
      textoDadosSalvos(null, agora: agora),
      'Sem internet · nenhum dado salvo ainda',
    );
  });

  // Teste de widget: desenha a faixa de verdade (numa tela de teste) e
  // confere se o texto e o ícone de nuvem aparecem.
  testWidgets('a faixa mostra o texto', (tester) async {
    // pumpWidget monta a tela; MaterialApp e Scaffold dão o tema e o fundo
    // que o widget precisa para ser desenhado.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvisoDadosSalvos(
            atualizadoEm: DateTime(2026, 11, 17, 14, 30),
            agora: agora,
          ),
        ),
      ),
    );

    // findsOneWidget: tem que existir exatamente um na tela.
    expect(find.text('Sem internet · dados de hoje, 14:30'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });
}
