// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 17/11/2026
// Descrição: Testa o texto da faixa que avisa, sem internet, de quando são os
// dados salvos no celular (issue #74).

import 'package:app/widgets/aviso_dados_salvos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final agora = DateTime(2026, 11, 17, 20, 0);

  test('dados salvos hoje mostram "de hoje" e o horário', () {
    expect(
      textoDadosSalvos(DateTime(2026, 11, 17, 14, 30), agora: agora),
      'Sem internet · dados de hoje, 14:30',
    );
  });

  test('dados salvos ontem mostram "de ontem"', () {
    expect(
      textoDadosSalvos(DateTime(2026, 11, 16, 8, 5), agora: agora),
      'Sem internet · dados de ontem, 08:05',
    );
  });

  test('dados mais antigos mostram a data', () {
    expect(
      textoDadosSalvos(DateTime(2026, 11, 12, 9, 10), agora: agora),
      'Sem internet · dados de 12/11, 09:10',
    );
  });

  test('sem nada salvo avisa que não há dados', () {
    expect(
      textoDadosSalvos(null, agora: agora),
      'Sem internet · nenhum dado salvo ainda',
    );
  });

  testWidgets('a faixa mostra o texto', (tester) async {
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

    expect(find.text('Sem internet · dados de hoje, 14:30'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });
}
