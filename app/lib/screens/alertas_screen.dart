// Estrutura criada em 28/10/26 — implementação pendente (responsável: a definir)
// Descrição: Tela 5 do relatório — lista de todos os alertas recebidos, com filtro por tipo (Todos, Geada, Seca, Chuva).

import 'package:flutter/material.dart';

import '../widgets/tela_em_construcao.dart';

class AlertasScreen extends StatelessWidget {
  const AlertasScreen({super.key});

  // TODO(P029): listar alertas via AlertaService, chips de filtro por TipoAlerta e navegação para DetalheAlertaScreen.
  @override
  Widget build(BuildContext context) {
    return const TelaEmConstrucao(titulo: 'Alertas');
  }
}
