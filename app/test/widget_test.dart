// Rafael Mendes Valente - 25002875
// Data: 07/10/26
// Horário: 19h15 - 23h15
// Descrição: Teste de widget para a tela inicial do aplicativo. Verifica se o
// nome do app, o botão "Começar" e o link "Já tenho uma conta" estão presentes na tela

import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('Splash exibe nome, tagline e botões', (WidgetTester tester) async {
    await tester.pumpWidget(const ClimAlertaApp());

    expect(find.text('ClimAlerta'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
    expect(find.text('Já tenho uma conta'), findsOneWidget);
  });
}