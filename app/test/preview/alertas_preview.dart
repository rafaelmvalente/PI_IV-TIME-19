// Caique Vasconcelos Naimi - 25004208
// Data: 28/10/2026
// Descrição: Prévia das telas 5, 6 e 7 com alertas de exemplo, para ver as
// telas sem o backend. Rodar com: flutter run -t test/preview/alertas_preview.dart

import 'package:app/screens/alertas_screen.dart';
import 'package:flutter/material.dart';

import 'alertas_exemplo.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AlertasScreen(
        carregarAlertas: () async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return alertasDeExemplo(DateTime.now());
        },
      ),
    ),
  );
}

