// Data: 11/11/2026
// Descrição: Valida que o app abre direto no dashboard quando há login salvo.

import 'package:app/main.dart';
import 'package:app/models/coordenada.dart';
import 'package:app/models/propriedade.dart';
import 'package:app/models/usuario.dart';
import 'package:app/screens/dashboard_screen.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/session/sessao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SessaoController> _abrir(
  WidgetTester tester,
  Future<Conta?> Function() restaurar,
) async {
  final sessao = SessaoController();
  await tester.pumpWidget(
    SessaoScope(
      controller: sessao,
      child: MaterialApp(
        home: AbrirSessaoSalva(
          restaurar: restaurar,
          child: const Text('splash'),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return sessao;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('com login salvo, entra na sessão e abre o dashboard', (
    tester,
  ) async {
    final sessao = await _abrir(
      tester,
      () async => const Conta(
        login: 'ana@exemplo.com',
        usuario: Usuario(id: 'u1', nome: 'Ana', telefone: '19987654321'),
        propriedade: Propriedade(
          id: 'p1',
          nome: 'Sítio Verde',
          cultivo: TipoCultivo.soja,
          localizacao: Coordenada(latitude: -23.5, longitude: -46.6),
        ),
      ),
    );

    expect(sessao.logado, isTrue);
    expect(sessao.telefone, '19987654321');
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('sem login salvo, fica na splash', (tester) async {
    final sessao = await _abrir(tester, () async => null);

    expect(sessao.logado, isFalse);
    expect(find.text('splash'), findsOneWidget);
  });
}
