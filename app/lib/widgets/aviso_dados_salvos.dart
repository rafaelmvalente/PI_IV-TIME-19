// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 17/11/2026
// Descrição: Faixa do dashboard que avisa, sem internet, que os alertas e o
// clima mostrados são os salvos no celular e de quando eles são
// (ex.: "Sem internet · dados de hoje, 14:30"). Issue #74.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// Monta o texto da faixa: "hoje", "ontem" ou a data, sempre com o horário.
String textoDadosSalvos(DateTime? atualizadoEm, {DateTime? agora}) {
  if (atualizadoEm == null) return 'Sem internet · nenhum dado salvo ainda';

  final hoje = DateUtils.dateOnly(agora ?? DateTime.now());
  final dia = DateUtils.dateOnly(atualizadoEm);
  final diferenca = hoje.difference(dia).inDays;

  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  final hora =
      '${doisDigitos(atualizadoEm.hour)}:${doisDigitos(atualizadoEm.minute)}';
  final quando = switch (diferenca) {
    0 => 'de hoje',
    1 => 'de ontem',
    _ => 'de ${doisDigitos(dia.day)}/${doisDigitos(dia.month)}',
  };
  return 'Sem internet · dados $quando, $hora';
}

class AvisoDadosSalvos extends StatelessWidget {
  const AvisoDadosSalvos({super.key, required this.atualizadoEm, this.agora});

  // Quando o cache foi salvo (ArmazenamentoLocalService.ultimaAtualizacao).
  final DateTime? atualizadoEm;
  // Só para os testes fixarem o dia de "hoje".
  final DateTime? agora;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amareloSol.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amareloSol),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 20, color: AppColors.textoEscuro),
          const SizedBox(width: 10),
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
