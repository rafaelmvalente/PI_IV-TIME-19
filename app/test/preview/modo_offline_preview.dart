// Vinicius Santuci Virgolino - 25000294
// Data: 28/10/2026
// Descrição: Prévia da tela 10 (modo offline/SMS), para ver a tela sem
// precisar desligar a internet. Rodar com:
// flutter run -t test/preview/modo_offline_preview.dart

import 'package:app/screens/modo_offline_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ModoOfflineScreen(),
    ),
  );
}
