// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 18/11/2026
// Descrição: Testa o NotificacaoService (issue #31) com um Firebase falso:
// envio do token, permissão, e abertura do alerta nos três estados do app.

import 'dart:async';

import 'package:app/services/notificacao_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProvedorFalso implements ProvedorDePush {
  _ProvedorFalso({this.configurado = true, this.permissao = true})
    : token = 'token-do-aparelho';

  final bool configurado;
  final bool permissao;
  final String? token;

  MensagemDePush? inicial;
  int pedidosDePermissao = 0;

  final renovado = StreamController<String>.broadcast();
  final aberto = StreamController<MensagemDePush>.broadcast();
  final primeiroPlano = StreamController<MensagemDePush>.broadcast();

  @override
  Future<bool> inicializar() async => configurado;

  @override
  Future<bool> pedirPermissao() async {
    pedidosDePermissao++;
    return permissao;
  }

  @override
  Future<String?> obterToken() async => token;

  @override
  Stream<String> get tokenRenovado => renovado.stream;

  @override
  Stream<MensagemDePush> get comAppAberto => primeiroPlano.stream;

  @override
  Stream<MensagemDePush> get aoAbrirNotificacao => aberto.stream;

  @override
  Future<MensagemDePush?> mensagemInicial() async => inicial;
}

class _Cenario {
  _Cenario(this.provedor, {bool falhaAoEnviar = false}) {
    servico = NotificacaoService(
      provedor: provedor,
      enviarToken: (token) async {
        if (falhaAoEnviar) throw StateError('sem internet');
        tokensEnviados.add(token);
      },
      removerToken: (token) async {
        if (falhaAoEnviar) throw StateError('sem internet');
        tokensRemovidos.add(token);
      },
      abrirAlerta: alertasAbertos.add,
      mostrarAviso: avisos.add,
    );
  }

  final _ProvedorFalso provedor;
  late final NotificacaoService servico;
  final tokensEnviados = <String>[];
  final tokensRemovidos = <String>[];
  final alertasAbertos = <String>[];
  final avisos = <MensagemDePush>[];
}

// Dá tempo de os eventos dos streams chegarem ao serviço.
Future<void> _esperar() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'sem Firebase configurado, não pede permissão nem envia token',
    () async {
      final c = _Cenario(_ProvedorFalso(configurado: false));

      await c.servico.aoEntrar();

      expect(c.provedor.pedidosDePermissao, 0);
      expect(c.tokensEnviados, isEmpty);
    },
  );

  test('ao entrar, pede permissão e envia o token do aparelho', () async {
    final c = _Cenario(_ProvedorFalso());

    await c.servico.aoEntrar();

    expect(c.provedor.pedidosDePermissao, 1);
    expect(c.tokensEnviados, ['token-do-aparelho']);
  });

  test('se o produtor negar a permissão, o token não é enviado', () async {
    final c = _Cenario(_ProvedorFalso(permissao: false));

    await c.servico.aoEntrar();

    expect(c.tokensEnviados, isEmpty);
  });

  test('ao sair, pede ao backend para esquecer o aparelho', () async {
    final c = _Cenario(_ProvedorFalso());

    await c.servico.esquecerAparelho();

    expect(c.tokensRemovidos, ['token-do-aparelho']);
  });

  test('sem Firebase, sair não chama o backend', () async {
    final c = _Cenario(_ProvedorFalso(configurado: false));

    await c.servico.esquecerAparelho();

    expect(c.tokensRemovidos, isEmpty);
  });

  test('sem internet ao sair, não dá erro', () async {
    final c = _Cenario(_ProvedorFalso(), falhaAoEnviar: true);

    await c.servico.esquecerAparelho();

    expect(c.tokensRemovidos, isEmpty);
  });

  test('falha ao enviar o token não derruba o app', () async {
    final c = _Cenario(_ProvedorFalso(), falhaAoEnviar: true);

    await c.servico.aoEntrar();

    expect(c.tokensEnviados, isEmpty);
  });

  test(
    'token renovado pelo Firebase é reenviado só se estiver logado',
    () async {
      final c = _Cenario(_ProvedorFalso());
      await c.servico.iniciar();

      c.provedor.renovado.add('token-antes-do-login');
      await _esperar();
      expect(c.tokensEnviados, isEmpty);

      await c.servico.aoEntrar();
      c.provedor.renovado.add('token-novo');
      await _esperar();
      expect(c.tokensEnviados, ['token-do-aparelho', 'token-novo']);

      c.servico.aoSair();
      c.provedor.renovado.add('token-depois-de-sair');
      await _esperar();
      expect(c.tokensEnviados, ['token-do-aparelho', 'token-novo']);
    },
  );

  test('app aberto: mostra o aviso da notificação', () async {
    final c = _Cenario(_ProvedorFalso());
    await c.servico.iniciar();

    c.provedor.primeiroPlano.add(
      const MensagemDePush(alertaId: 'a1', titulo: 'Risco alto de geada'),
    );
    await _esperar();

    expect(c.avisos, hasLength(1));
    expect(c.avisos.first.titulo, 'Risco alto de geada');
    expect(c.alertasAbertos, isEmpty);
  });

  test('segundo plano: tocar na notificação abre o alerta', () async {
    final c = _Cenario(_ProvedorFalso());
    await c.servico.aoEntrar();

    c.provedor.aberto.add(const MensagemDePush(alertaId: 'a1'));
    await _esperar();

    expect(c.alertasAbertos, ['a1']);
  });

  test('notificação sem alertaId não abre nada', () async {
    final c = _Cenario(_ProvedorFalso());
    await c.servico.aoEntrar();

    c.provedor.aberto.add(const MensagemDePush(titulo: 'Sem alerta'));
    await _esperar();

    expect(c.alertasAbertos, isEmpty);
  });

  test(
    'app fechado: abre o alerta da notificação só depois do login',
    () async {
      final provedor = _ProvedorFalso()
        ..inicial = const MensagemDePush(alertaId: 'a7');
      final c = _Cenario(provedor);

      await c.servico.iniciar();
      expect(c.alertasAbertos, isEmpty);

      await c.servico.aoEntrar();
      expect(c.alertasAbertos, ['a7']);

      // Abre uma vez só: um novo login não repete.
      c.servico.aoSair();
      await c.servico.aoEntrar();
      expect(c.alertasAbertos, ['a7']);
    },
  );

  test('toque na notificação antes do login fica esperando o login', () async {
    final c = _Cenario(_ProvedorFalso());
    await c.servico.iniciar();

    c.provedor.aberto.add(const MensagemDePush(alertaId: 'a9'));
    await _esperar();
    expect(c.alertasAbertos, isEmpty);

    await c.servico.aoEntrar();
    expect(c.alertasAbertos, ['a9']);
  });
}
