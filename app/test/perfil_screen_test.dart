import 'package:app/models/coordenada.dart';
import 'package:app/models/propriedade.dart';
import 'package:app/screens/perfil_screen.dart';
import 'package:app/session/sessao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SessaoController _sessaoLogada() {
  final sessao = SessaoController();
  sessao.entrar(
    login: 'antonio@exemplo.com',
    propriedade: const Propriedade(
      nome: 'Sítio Boa Vista',
      cultivo: TipoCultivo.milho,
      localizacao: Coordenada(latitude: -22.9056, longitude: -47.0608),
      areaHectares: 3.5,
    ),
  );
  return sessao;
}

Future<void> _abrir(
  WidgetTester tester,
  SessaoController sessao, {
  VoidCallback? onSair,
  VoidCallback? onTentarNovamente,
}) async {
  // Tela alta para tudo ficar visível sem precisar rolar.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: PerfilScreen(
        sessao: sessao,
        onSair: onSair,
        onTentarNovamente: onTentarNovamente,
      ),
    ),
  );
}

void main() {
  testWidgets('avisa quando não há ninguém logado', (tester) async {
    await _abrir(tester, SessaoController());

    expect(find.text('Você não está logado'), findsOneWidget);
  });

  testWidgets('mostra a conta e os dados da propriedade', (tester) async {
    await _abrir(tester, _sessaoLogada());

    expect(find.text('antonio@exemplo.com'), findsOneWidget);
    expect(find.text('Sítio Boa Vista'), findsOneWidget);
    expect(find.text('Milho'), findsOneWidget);
    expect(find.text('3,5 ha'), findsOneWidget);
    expect(
      find.text('Latitude -22.9056, longitude -47.0608'),
      findsOneWidget,
    );
  });

  testWidgets('avisa quando não há propriedade cadastrada', (tester) async {
    final sessao = SessaoController()..entrar(login: 'antonio@exemplo.com');
    await _abrir(tester, sessao);

    expect(find.text('Você ainda não cadastrou uma propriedade.'), findsOneWidget);
  });

  testWidgets('mostra carregando', (tester) async {
    final sessao = _sessaoLogada()..definirCarregando(true);
    await _abrir(tester, sessao);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('mostra erro e botão de tentar novamente', (tester) async {
    final sessao = _sessaoLogada()..definirErro('Sem conexão com o servidor.');
    var tentou = false;
    await _abrir(tester, sessao, onTentarNovamente: () => tentou = true);

    expect(find.text('Sem conexão com o servidor.'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    expect(tentou, isTrue);
  });

  testWidgets('liga o alerta por voz', (tester) async {
    final sessao = _sessaoLogada();
    await _abrir(tester, sessao);

    await tester.tap(find.text('Voz'));
    await tester.pump();

    expect(sessao.preferencias.voz, isTrue);
  });

  testWidgets('não deixa desligar todos os jeitos de receber alerta',
      (tester) async {
    final sessao = _sessaoLogada(); // só "Texto" está ligado
    await _abrir(tester, sessao);

    await tester.tap(find.text('Texto'));
    await tester.pump();

    expect(find.textContaining('pelo menos um'), findsOneWidget);
    expect(sessao.preferencias.texto, isTrue);
  });

  testWidgets('edita nome e cultivo da propriedade', (tester) async {
    final sessao = _sessaoLogada();
    await _abrir(tester, sessao);

    await tester.tap(find.text('Editar propriedade'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Sítio Novo');
    await tester.tap(find.text('Feijão'));
    await tester.pump();
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(sessao.propriedade?.nome, 'Sítio Novo');
    expect(sessao.propriedade?.cultivo, TipoCultivo.feijao);
    expect(find.text('Sítio Novo'), findsOneWidget);
  });

  testWidgets('sai da conta depois de confirmar', (tester) async {
    final sessao = _sessaoLogada();
    var saiu = false;
    await _abrir(tester, sessao, onSair: () => saiu = true);

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(sessao.logado, isFalse);
    expect(saiu, isTrue);
  });
}
