import 'package:app/screens/recuperar_senha_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _abrir(
  WidgetTester tester, {
  Future<void> Function(String login)? onEnviar,
}) async {
  await tester.pumpWidget(
    MaterialApp(home: RecuperarSenhaScreen(onEnviar: onEnviar)),
  );
}

Future<void> _preencherEEnviar(WidgetTester tester, String login) async {
  await tester.enterText(find.byType(TextFormField), login);
  await tester.tap(find.text('Enviar link de recuperação'));
}

void main() {
  testWidgets('não aceita e-mail ou telefone inválido', (tester) async {
    await _abrir(tester, onEnviar: (login) async {});

    await _preencherEEnviar(tester, 'abc');
    await tester.pump();

    expect(find.text('Digite um e-mail ou telefone válido'), findsOneWidget);
  });

  testWidgets('e-mail válido chama onEnviar e mostra a confirmação',
      (tester) async {
    String? recebido;
    await _abrir(tester, onEnviar: (login) async => recebido = login);

    await _preencherEEnviar(tester, 'antonio@exemplo.com');
    await tester.pumpAndSettle();

    expect(recebido, 'antonio@exemplo.com');
    expect(find.text('Verifique seu e-mail ou telefone'), findsOneWidget);
  });

  testWidgets('telefone válido também é aceito', (tester) async {
    String? recebido;
    await _abrir(tester, onEnviar: (login) async => recebido = login);

    await _preencherEEnviar(tester, '(19) 99999-1234');
    await tester.pumpAndSettle();

    expect(recebido, '(19) 99999-1234');
    expect(find.text('Verifique seu e-mail ou telefone'), findsOneWidget);
  });

  testWidgets('avisa que o serviço não está disponível quando não há onEnviar',
      (tester) async {
    await _abrir(tester);

    await _preencherEEnviar(tester, 'antonio@exemplo.com');
    await tester.pump();

    expect(find.textContaining('ainda não está disponível'), findsOneWidget);
    expect(find.text('Verifique seu e-mail ou telefone'), findsNothing);
  });

  testWidgets('mostra erro quando o envio falha', (tester) async {
    await _abrir(
      tester,
      onEnviar: (login) async {
        throw Exception('falhou');
      },
    );

    await _preencherEEnviar(tester, 'antonio@exemplo.com');
    await tester.pumpAndSettle();

    expect(find.textContaining('Não foi possível enviar'), findsOneWidget);
  });
}
