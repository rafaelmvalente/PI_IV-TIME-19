// Rafael Mendes Valente - 25002875
// Data: 07/10/26
// Horário: 19h15 - 23h15
// Descrição: Inicia o app, define o tema, o título e a tela inicial

import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'session/sessao.dart';

void main() {
  // A sessão fica acima do MaterialApp para todas as telas conseguirem ler
  // quem está logado e a propriedade atual (SessaoScope.of(context)).
  runApp(
    SessaoScope(
      controller: SessaoController(),
      child: const ClimAlertaApp(),
    ),
  );
}

class ClimAlertaApp extends StatelessWidget {
  const ClimAlertaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
