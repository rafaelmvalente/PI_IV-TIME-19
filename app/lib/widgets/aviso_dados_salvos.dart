// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 17/11/2026
// Descrição: Faixa do dashboard que avisa, sem internet, que os alertas e o
// clima mostrados são os salvos no celular e de quando eles são
// (ex.: "Sem internet · dados de hoje, 14:30"). Issue #74.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// Monta o texto da faixa: "hoje", "ontem" ou a data, sempre com o horário.
// Fica fora da classe (função solta) para ser testada sem desenhar a tela.
// "agora" é opcional: os testes passam uma data fixa; o app usa a data atual.
String textoDadosSalvos(DateTime? atualizadoEm, {DateTime? agora}) {
  // Primeira vez sem internet e nada salvo ainda no celular.
  if (atualizadoEm == null) return 'Sem internet · nenhum dado salvo ainda';

  // dateOnly zera as horas: assim comparamos só os dias. Sem isso, 23h de
  // ontem e 1h de hoje dariam menos de 1 dia de diferença e sairia "hoje".
  final hoje = DateUtils.dateOnly(agora ?? DateTime.now());
  final dia = DateUtils.dateOnly(atualizadoEm);
  final diferenca = hoje.difference(dia).inDays;

  // Completa com zero à esquerda: 9 vira "09" (para mostrar 09:05).
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  final hora =
      '${doisDigitos(atualizadoEm.hour)}:${doisDigitos(atualizadoEm.minute)}';
  // 0 dias = hoje, 1 dia = ontem, mais que isso = a data (dia/mês).
  final quando = switch (diferenca) {
    0 => 'de hoje',
    1 => 'de ontem',
    _ => 'de ${doisDigitos(dia.day)}/${doisDigitos(dia.month)}',
  };
  return 'Sem internet · dados $quando, $hora';
}

// A faixa amarela em si. O dashboard só a mostra quando está sem internet.
class AvisoDadosSalvos extends StatelessWidget {
  const AvisoDadosSalvos({super.key, required this.atualizadoEm, this.agora});

  // Quando o cache foi salvo (ArmazenamentoLocalService.ultimaAtualizacao).
  final DateTime? atualizadoEm;
  // Só para os testes fixarem o dia de "hoje".
  final DateTime? agora;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Ocupa toda a largura da tela.
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      // Fundo amarelo claro (25% de opacidade) com borda amarela forte:
      // chama atenção sem parecer um erro (que seria vermelho).
      decoration: BoxDecoration(
        color: AppColors.amareloSol.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amareloSol),
      ),
      child: Row(
        children: [
          // Ícone de nuvem cortada: o símbolo comum de "sem conexão".
          const Icon(Icons.cloud_off, size: 20, color: AppColors.textoEscuro),
          const SizedBox(width: 10),
          // Expanded: o texto quebra a linha em telas estreitas em vez de
          // passar da borda.
          Expanded(
            child: Text(
              textoDadosSalvos(atualizadoEm, agora: agora),
              style: const TextStyle(
                color: AppColors.textoEscuro,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
