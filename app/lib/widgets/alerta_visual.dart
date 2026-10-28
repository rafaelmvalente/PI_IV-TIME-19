// Data: 28/10/2026
// Descrição: Ícone, título e data dos alertas, compartilhados pela lista e
// pelo detalhe para que as duas telas mostrem o alerta do mesmo jeito.

import 'package:flutter/material.dart';

import '../models/alerta.dart';

class IconeAlerta extends StatelessWidget {
  const IconeAlerta({super.key, required this.tipo, this.raio = 22});

  final TipoAlerta tipo;
  final double raio;

  @override
  Widget build(BuildContext context) {
    final (icone, cor, fundo) = switch (tipo) {
      TipoAlerta.geada => (
          Icons.ac_unit,
          const Color(0xFF2E8BC0),
          const Color(0xFFDDF1F8),
        ),
      TipoAlerta.seca => (
          Icons.wb_sunny,
          const Color(0xFFE9A317),
          const Color(0xFFFFF1CC),
        ),
      TipoAlerta.chuvaForte => (
          Icons.water_drop,
          const Color(0xFF3B82C4),
          const Color(0xFFE3F0FB),
        ),
    };

    return CircleAvatar(
      radius: raio,
      backgroundColor: fundo,
      child: Icon(
        icone,
        color: cor,
        size: raio * 1.1,
        semanticLabel: tipo.rotulo,
      ),
    );
  }
}

String tituloDoAlerta(TipoAlerta tipo) => switch (tipo) {
      TipoAlerta.geada => 'Risco de geada',
      TipoAlerta.seca => 'Seca prolongada',
      TipoAlerta.chuvaForte => 'Risco de chuva forte',
    };

const _meses = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

// Ex.: "Hoje, 22 de ago · 06:00", "Amanhã, 23 de ago · 14:00", "25 de ago · 10:00".
String formatarQuando(DateTime data, {DateTime? agora}) {
  final hoje = agora ?? DateTime.now();
  final amanha = DateTime(hoje.year, hoje.month, hoje.day + 1);

  final prefixo = DateUtils.isSameDay(data, hoje)
      ? 'Hoje, '
      : DateUtils.isSameDay(data, amanha)
          ? 'Amanhã, '
          : '';
  final hora = '${data.hour.toString().padLeft(2, '0')}:'
      '${data.minute.toString().padLeft(2, '0')}';

  return '$prefixo${data.day} de ${_meses[data.month - 1]} · $hora';
}
