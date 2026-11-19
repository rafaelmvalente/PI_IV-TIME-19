// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 28/10/2026
// Descrição: Prévia da tela 10 (modo offline), para ver a tela sem
// precisar desligar a internet. Rodar com:
// flutter run -t test/preview/modo_offline_preview.dart

import 'package:app/screens/modo_offline_screen.dart';
import 'package:flutter/material.dart';

// Um "main" separado do app: abre direto a tela de modo offline, sem passar
// por login, dashboard nem queda de conexão.
void main() {
  runApp(
    const MaterialApp(
      // Esconde a faixa "DEBUG" do canto da tela.
      debugShowCheckedModeBanner: false,
      home: ModoOfflineScreen(),
    ),
  );
}
