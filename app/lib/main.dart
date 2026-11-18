// Rafael Mendes Valente - 25002875
// Data: 07/10/26
// Horário: 19h15 - 23h15
// Descrição: Inicia o app, define o tema, o título e a tela inicial
// Caio Ávila Marchi - 25008101
// Data: 18/11/2026
// Descrição: Liga o push (Firebase) ao app: guarda o token ao entrar e abre o
// alerta quando o produtor toca na notificação (issue #31).

import 'dart:async';

import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/detalhe_alerta_screen.dart';
import 'screens/splash_screen.dart';
import 'services/alerta_service.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/notificacao_service.dart';
import 'services/provedor_firebase.dart';
import 'session/sessao.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Chaves para abrir telas e avisos a partir de uma notificação, que chega
  // de fora de qualquer tela.
  final navigatorKey = GlobalKey<NavigatorState>();
  final mensagensKey = GlobalKey<ScaffoldMessengerState>();

  // Abre o detalhe do alerta que veio na notificação.
  Future<void> abrirAlerta(String alertaId) async {
    try {
      final alerta = await AlertaService().buscarPorId(alertaId);
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => DetalheAlertaScreen(alerta: alerta)),
      );
    } catch (_) {
      mensagensKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o alerta agora.')),
      );
    }
  }

  final notificacoes = NotificacaoService(
    provedor: ProvedorFirebase(),
    enviarToken: (token) =>
        ApiClient().patch('/auth/me/push-token', body: {'token': token}),
    abrirAlerta: abrirAlerta,
    // Com o app aberto o Android não mostra a notificação sozinho: mostramos
    // um aviso na tela, com o botão "Ver" para abrir o alerta.
    mostrarAviso: (mensagem) {
      final alertaId = mensagem.alertaId;
      mensagensKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            [
              mensagem.titulo,
              mensagem.corpo,
            ].whereType<String>().where((t) => t.isNotEmpty).join('\n'),
          ),
          duration: const Duration(seconds: 10),
          action: alertaId == null
              ? null
              : SnackBarAction(
                  label: 'Ver',
                  onPressed: () => abrirAlerta(alertaId),
                ),
        ),
      );
    },
  );

  // A sessão fica acima do MaterialApp para todas as telas conseguirem ler
  // quem está logado e a propriedade atual (SessaoScope.of(context)).
  final sessao = SessaoController();

  // Login novo e sessão restaurada passam por sessao.entrar(); sair, por sessao.sair().
  // Ouvir a sessão aqui evita mexer nas telas de login e de perfil.
  var estavaLogado = false;
  sessao.addListener(() {
    final logado = sessao.logado;
    if (logado && !estavaLogado) {
      unawaited(notificacoes.aoEntrar());
    } else if (!logado && estavaLogado) {
      notificacoes.aoSair();
    }
    estavaLogado = logado;
  });

  // Prepara o Firebase em segundo plano. Sem configuração, o app funciona igual,
  // só sem push.
  unawaited(notificacoes.iniciar());

  runApp(
    SessaoScope(
      controller: sessao,
      child: ClimAlertaApp(
        navigatorKey: navigatorKey,
        mensagensKey: mensagensKey,
      ),
    ),
  );
}

class ClimAlertaApp extends StatelessWidget {
  const ClimAlertaApp({super.key, this.navigatorKey, this.mensagensKey});

  // Usadas pelas notificações para abrir telas e mostrar avisos.
  final GlobalKey<NavigatorState>? navigatorKey;
  final GlobalKey<ScaffoldMessengerState>? mensagensKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: mensagensKey,
      title: 'ClimAlerta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E7B58),
      ),
      home: const AbrirSessaoSalva(child: SplashScreen()),
    );
  }
}

// Abre direto no dashboard quando há um login salvo e ainda válido.
// Sem login (ou sem internet para conferir), mostra a tela de baixo (splash).
class AbrirSessaoSalva extends StatefulWidget {
  const AbrirSessaoSalva({super.key, required this.child, this.restaurar});

  final Widget child;
  // Quem abre a tela pode trocar de onde vem a conta (útil nos testes).
  final Future<Conta?> Function()? restaurar;

  @override
  State<AbrirSessaoSalva> createState() => _AbrirSessaoSalvaState();
}

class _AbrirSessaoSalvaState extends State<AbrirSessaoSalva> {
  @override
  void initState() {
    super.initState();
    _tentarRestaurar();
  }

  Future<void> _tentarRestaurar() async {
    Conta? conta;
    try {
      conta = await (widget.restaurar ?? AuthService().restaurarSessao)();
    } catch (_) {
      return; // Sem API configurada ou sem armazenamento: segue pela splash.
    }
    final propriedade = conta?.propriedade;
    if (conta == null || propriedade == null || !mounted) return;

    SessaoScope.of(context).entrar(
      login: conta.login,
      nome: conta.usuario.nome,
      telefone: conta.usuario.telefone,
      propriedade: propriedade,
      preferencias: conta.usuario.preferencias,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(propriedade: propriedade),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
