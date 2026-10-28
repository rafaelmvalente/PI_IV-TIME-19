// Estrutura criada em 28/10/26 — implementação pendente (responsável: a definir)
// Descrição: Corpo provisório das telas que ainda não foram implementadas.
// Deve deixar de ser usado à medida que cada tela for desenvolvida.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TelaEmConstrucao extends StatelessWidget {
  const TelaEmConstrucao({super.key, required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(title: Text(titulo)),
      body: const Center(
        child: Text(
          'Tela em construção',
          style: TextStyle(color: AppColors.textoSecundario),
        ),
      ),
    );
  }
}
