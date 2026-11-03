// Caique Vasconcelos Naimi - 25004208
// Data: 28/10/2026
// Descrição: Ícone, título e data dos alertas, compartilhados pela lista e
// pelo detalhe para que as duas telas mostrem o alerta do mesmo jeito. Também
// guarda o filtro por tipo e a mensagem de vazio/erro das listas.

import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../theme/app_colors.dart';

// Círculo colorido com o ícone do tipo de alerta (floco de neve, sol ou gota).
class IconeAlerta extends StatelessWidget {
  const IconeAlerta({super.key, required this.tipo, this.raio = 22});

  final TipoAlerta tipo;
  final double raio;

  @override
  Widget build(BuildContext context) {
    // O switch escolhe ícone, cor e fundo de acordo com o tipo. Como cobre
    // todos os tipos, o Dart avisa se um tipo novo for criado e esquecido aqui.
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
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

// Ex.: "Hoje, 22 de ago · 06:00", "Amanhã, 23 de ago · 14:00", "25 de ago · 10:00".
String formatarQuando(DateTime data, {DateTime? agora}) {
  final hoje = agora ?? DateTime.now();
  final amanha = DateTime(hoje.year, hoje.month, hoje.day + 1);

  // isSameDay compara só o dia (ignora a hora), para escrever "Hoje" ou "Amanhã".
  final prefixo = DateUtils.isSameDay(data, hoje)
      ? 'Hoje, '
      : DateUtils.isSameDay(data, amanha)
      ? 'Amanhã, '
      : '';
  // padLeft completa com zero à esquerda: 6 vira "06".
  final hora =
      '${data.hour.toString().padLeft(2, '0')}:'
      '${data.minute.toString().padLeft(2, '0')}';

  return '$prefixo${data.day} de ${_meses[data.month - 1]} · $hora';
}

// Botões de filtro por tipo (Todos, Geada, Seca, Chuva), usados nas telas de
// Alertas e de Histórico. O tipo null significa "Todos".
class FiltroTipoAlerta extends StatelessWidget {
  const FiltroTipoAlerta({
    super.key,
    required this.selecionado,
    required this.aoMudar,
  });

  final TipoAlerta? selecionado;
  final ValueChanged<TipoAlerta?> aoMudar;

  // Cada filtro é um par (tipo, texto do botão).
  static const _filtros = <(TipoAlerta?, String)>[
    (null, 'Todos'),
    (TipoAlerta.geada, 'Geada'),
    (TipoAlerta.seca, 'Seca'),
    (TipoAlerta.chuvaForte, 'Chuva'),
  ];

  @override
  Widget build(BuildContext context) {
    // Rolagem horizontal para os filtros não estourarem em telas estreitas.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (tipo, rotulo) in _filtros)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              // ChoiceChip é o botão em formato de pílula do protótipo; o
              // selecionado fica verde com texto branco.
              child: ChoiceChip(
                label: Text(rotulo),
                selected: selecionado == tipo,
                showCheckmark: false,
                selectedColor: AppColors.verde,
                backgroundColor: const Color(0xFFE6EBE8),
                side: BorderSide.none,
                shape: const StadiumBorder(),
                labelStyle: TextStyle(
                  color: selecionado == tipo
                      ? Colors.white
                      : AppColors.textoEscuro,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => aoMudar(tipo),
              ),
            ),
        ],
      ),
    );
  }
}

// Mensagem centralizada para os estados de vazio e de erro das listas.
class MensagemAlertas extends StatelessWidget {
  const MensagemAlertas({
    super.key,
    required this.icone,
    required this.texto,
    this.botao,
    this.aoTocar,
  });

  final IconData icone;
  final String texto;
  final String? botao;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 56, color: AppColors.textoSecundario),
          const SizedBox(height: 12),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textoEscuro, fontSize: 16),
          ),
          if (botao != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.verde,
                side: const BorderSide(color: AppColors.verde),
              ),
              onPressed: aoTocar,
              child: Text(botao!),
            ),
          ],
        ],
      ),
    );
  }
}
