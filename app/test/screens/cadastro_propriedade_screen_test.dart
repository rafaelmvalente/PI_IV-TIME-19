// Caique Vasconcelos Naimi - 25004208
// Data: 03/11/2026
// Descrição: Testes de widget do cadastro de propriedade: validações ao
// salvar vazio e retorno da Propriedade preenchida, com o estágio da lavoura.

import 'package:app/models/coordenada.dart';
import 'package:app/models/estagio_lavoura.dart';
import 'package:app/models/propriedade.dart';
import 'package:app/screens/cadastro_propriedade_screen.dart';
import 'package:app/services/localizacao_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// GPS simulado: devolve sempre a mesma coordenada, sem pedir permissão.
class _GpsFalso extends LocalizacaoService {
  const _GpsFalso();

  @override
  Future<Coordenada> obterLocalizacaoAtual() async =>
      const Coordenada(latitude: -22.9, longitude: -47.06);
}

void main() {
  // Abre o cadastro a partir de outra tela, para receber o que ele devolve.
  Future<Propriedade? Function()> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Propriedade? resultado;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              resultado = await Navigator.of(context).push<Propriedade>(
                MaterialPageRoute(
                  builder: (_) => const CadastroPropriedadeScreen(
                    localizacaoService: _GpsFalso(),
                  ),
                ),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return () => resultado;
  }

  Future<void> escolher(WidgetTester tester, String dica, String opcao) async {
    await tester.tap(find.text(dica));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcao).last);
    await tester.pumpAndSettle();
  }

  testWidgets('salvar sem preencher mostra as mensagens de validação',
      (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome da propriedade'), findsOneWidget);
    expect(find.text('Selecione o tipo de cultivo'), findsWidgets);
    expect(find.text('Registre a localização da propriedade'), findsOneWidget);
    expect(find.byType(CadastroPropriedadeScreen), findsOneWidget);
  });

  testWidgets('salva e devolve a propriedade com o estágio da lavoura',
      (tester) async {
    final resultado = await abrir(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Sítio Novo');
    await escolher(tester, 'Selecione o tipo de cultivo', 'Café');
    await escolher(tester, 'Selecione o estágio atual', 'Floração');
    await tester.tap(find.text('Usar minha localização'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final propriedade = resultado();
    expect(propriedade, isNotNull);
    expect(propriedade!.nome, 'Sítio Novo');
    expect(propriedade.cultivo, TipoCultivo.cafe);
    expect(propriedade.estagio, EstagioLavoura.floracao);
    expect(propriedade.localizacao.latitude, -22.9);
  });

  testWidgets('o estágio é opcional', (tester) async {
    final resultado = await abrir(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Sítio Novo');
    await escolher(tester, 'Selecione o tipo de cultivo', 'Milho');
    await tester.tap(find.text('Usar minha localização'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(resultado(), isNotNull);
    expect(resultado()!.estagio, isNull);
  });
}
