// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 18/11/2026
// Descrição: Recebe as notificações push dos alertas (issue #31). Pede permissão,
// envia o token do aparelho ao backend e abre o detalhe do alerta quando o
// produtor toca na notificação, com o app aberto, em segundo plano ou fechado.
// Quem fala com o Firebase de verdade é o ProvedorFirebase; aqui fica só a
// lógica, atrás da interface ProvedorDePush, para poder ser testada sem celular.

import 'dart:async';

/// O que interessa de uma notificação: o alerta que ela anuncia e o texto.
class MensagemDePush {
  const MensagemDePush({this.alertaId, this.titulo, this.corpo});

  final String? alertaId;
  final String? titulo;
  final String? corpo;
}

/// Quem de fato fala com o Firebase. O app usa o ProvedorFirebase; os testes,
/// um provedor falso.
abstract class ProvedorDePush {
  /// Devolve false quando o Firebase não está configurado ou o aparelho não
  /// suporta (web, Windows). Nesse caso o app funciona igual, só sem push.
  Future<bool> inicializar();

  /// Pede permissão para mostrar notificações. Devolve true se o produtor aceitou.
  Future<bool> pedirPermissao();

  Future<String?> obterToken();

  /// O Firebase pode trocar o token do aparelho de tempos em tempos.
  Stream<String> get tokenRenovado;

  /// Notificação que chegou com o app aberto.
  Stream<MensagemDePush> get comAppAberto;

  /// Produtor tocou na notificação com o app em segundo plano.
  Stream<MensagemDePush> get aoAbrirNotificacao;

  /// Notificação em que o produtor tocou para abrir o app que estava fechado.
  Future<MensagemDePush?> mensagemInicial();
}

class NotificacaoService {
  NotificacaoService({
    required this._provedor,
    required this._enviarToken,
    required this._abrirAlerta,
    required this._mostrarAviso,
  });

  final ProvedorDePush _provedor;
  final Future<void> Function(String token) _enviarToken;
  final void Function(String alertaId) _abrirAlerta;
  final void Function(MensagemDePush mensagem) _mostrarAviso;

  final List<StreamSubscription<Object?>> _assinaturas = [];
  Future<void>? _iniciando;
  bool _ativo = false;
  bool _logado = false;

  // Notificação que o produtor tocou antes de estar logado. É aberta depois do login.
  MensagemDePush? _pendente;

  /// Liga o Firebase e começa a escutar as notificações. Pode ser chamado mais
  /// de uma vez: só a primeira faz alguma coisa.
  Future<void> iniciar() => _iniciando ??= _iniciar();

  Future<void> _iniciar() async {
    try {
      _ativo = await _provedor.inicializar();
      if (!_ativo) return;

      _pendente = await _provedor.mensagemInicial();
      _assinaturas.add(_provedor.comAppAberto.listen(_mostrarAviso));
      _assinaturas.add(_provedor.aoAbrirNotificacao.listen(_aoTocar));
      _assinaturas.add(
        _provedor.tokenRenovado.listen((token) {
          if (_logado) unawaited(_enviar(token));
        }),
      );
    } catch (_) {
      // Push é um extra: se algo falhar aqui, o app segue funcionando sem ele.
      _ativo = false;
    }
  }

  /// Chamar quando o produtor entrar (login novo ou sessão restaurada).
  Future<void> aoEntrar() async {
    _logado = true;
    await iniciar();
    if (!_ativo) return;

    try {
      if (await _provedor.pedirPermissao()) {
        final token = await _provedor.obterToken();
        if (token != null && token.isNotEmpty) await _enviar(token);
      }
    } catch (_) {
      // Sem permissão ou sem token agora: tenta de novo no próximo login.
    }

    final pendente = _pendente;
    _pendente = null;
    if (pendente != null && _logado) _abrir(pendente);
  }

  /// Chamar quando o produtor sair da conta.
  void aoSair() {
    _logado = false;
  }

  Future<void> parar() async {
    for (final assinatura in _assinaturas) {
      await assinatura.cancel();
    }
    _assinaturas.clear();
  }

  void _aoTocar(MensagemDePush mensagem) {
    if (_logado) {
      _abrir(mensagem);
    } else {
      _pendente = mensagem; // abre assim que o produtor entrar
    }
  }

  void _abrir(MensagemDePush mensagem) {
    final alertaId = mensagem.alertaId;
    if (alertaId == null || alertaId.isEmpty) return;
    _abrirAlerta(alertaId);
  }

  Future<void> _enviar(String token) async {
    try {
      await _enviarToken(token);
    } catch (_) {
      // Sem internet agora: o token vai de novo no próximo login.
    }
  }
}
