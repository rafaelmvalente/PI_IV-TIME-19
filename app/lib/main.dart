// Rafael Mendes Valente - 25002875
// Data: 07/10/26
// Horário: 19h15 - 23h15
// Descrição: Inicia o app, define o tema, o título e a tela inicial

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
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
      home: const SplashScreen(),
    );
  }
}
