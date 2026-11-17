// Caique Vasconcelos Naimi - 25004208
// Data: 17/11/2026
// Descrição: Testes da tela de senha nova (issue #71).

import 'package:app/screens/recuperar_senha_screen.dart';
import 'package:app/screens/redefinir_senha_screen.dart';
import 'package:app/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _codigo = 'a' * 64;

Future<void> _abrir(
  WidgetTester tester,
  Future<void> Function(String token, String novaSenha) onRedefinir,
) async {
  await tester.pumpWidget(
    MaterialApp(home: RedefinirSenhaScreen(onRedefinir: onRedefinir)),
  );
}

Future<void> _preencher(
  WidgetTester tester, {
  required String codigo,
  required String senha,
  String? confirmacao,
}) async {
  final campos = find.byType(TextFormField);
  await tester.enterText(campos.at(0), codigo);
  await tester.enterText(campos.at(1), senha);
  await tester.enterText(campos.at(2), confirmacao ?? senha);
  await tester.tap(find.text('Salvar senha nova'));
  await tester.pumpAndSettle();
}

void main() {
  test('extrairToken aceita o link inteiro ou só o código', () {
    expect(
      extrairToken(' https://climalerta.app/redefinir?token=$_codigo '),
      _codigo,
    );
    expect(extrairToken(_codigo), _codigo);
  });

  testWidgets('cola o link do e-mail e troca a senha', (tester) async {
    String? token;
    String? senha;
    await _abrir(tester, (t, s) async {
      token = t;
      senha = s;
    });

    await _preencher(
      tester,
      codigo: 'https://climalerta.app/redefinir?token=$_codigo',
      senha: 'senhaNova123',
    );

    expect(token, _codigo);
    expect(senha, 'senhaNova123');
    expect(find.text('Senha alterada'), findsOneWidget);
  });

  testWidgets('não envia senha curta, diferente ou link incompleto',
      (tester) async {
    var chamou = false;
    await _abrir(tester, (_, _) async => chamou = true);

    await _preencher(tester, codigo: 'abc', senha: '123', confirmacao: '456');

    expect(find.text('Link incompleto. Copie o link inteiro do e-mail'),
        findsOneWidget);
    expect(find.text('A senha precisa ter pelo menos 8 caracteres'),
        findsOneWidget);
    expect(find.text('As senhas não são iguais'), findsOneWidget);
    expect(chamou, isFalse);
  });

  testWidgets('avisa quando o link expirou', (tester) async {
    await _abrir(tester, (_, _) async {
      throw const ApiException(
        statusCode: 400,
        code: 'INVALID_RESET_TOKEN',
        message: 'Link de recuperação inválido ou expirado.',
      );
    });

    await _preencher(tester, codigo: _codigo, senha: 'senhaNova123');

    expect(find.textContaining('expirou ou já foi usado'), findsOneWidget);
    expect(find.text('Senha alterada'), findsNothing);
  });

  testWidgets('avisa quando está sem internet', (tester) async {
    await _abrir(tester, (_, _) async {
      throw const ApiException(statusCode: 0, code: 'NETWORK', message: '');
    });

    await _preencher(tester, codigo: _codigo, senha: 'senhaNova123');

    expect(find.textContaining('Sem conexão'), findsOneWidget);
  });

  testWidgets('a partir de "Esqueceu sua senha?" volta direto para o login',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RecuperarSenhaScreen(
                  onEnviar: (_) async {},
                  onRedefinir: (_, _) async {},
                ),
              ),
            ),
            child: const Text('tela de login'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('tela de login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Já tenho o link do e-mail'));
    await tester.pumpAndSettle();
    await _preencher(tester, codigo: _codigo, senha: 'senhaNova123');
    await tester.tap(find.text('Voltar para o login'));
    await tester.pumpAndSettle();

    expect(find.text('tela de login'), findsOneWidget);
    expect(find.byType(RecuperarSenhaScreen), findsNothing);
  });
}
