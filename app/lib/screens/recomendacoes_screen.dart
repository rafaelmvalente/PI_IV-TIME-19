// Data: 28/10/2026
// Descrição: Tela 7 do relatório — orientação detalhada de como agir diante
// do risco do alerta: ação principal, como fazer e dicas extras.

import 'package:flutter/material.dart';

import '../models/recomendacao.dart';
import '../theme/app_colors.dart';

class RecomendacoesScreen extends StatelessWidget {
  const RecomendacoesScreen({super.key, required this.recomendacao});

  final Recomendacao recomendacao;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              child: Column(
                children: [
                  const Row(
                    children: [
                      BackButton(),
                      SizedBox(width: 8),
                      Text(
                        'Recomendação',
                        style: TextStyle(
                          color: AppColors.textoEscuro,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildCartao(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verde,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Entendi',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartao() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Ilustração simples (planta protegida), no lugar da imagem do protótipo.
          Container(
            width: 160,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFDDEFF8), AppColors.morroClaro],
              ),
            ),
            child: const Icon(Icons.eco, size: 56, color: AppColors.verde),
          ),
          const SizedBox(height: 16),
          Text(
            recomendacao.acao,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoEscuro,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (recomendacao.detalhe.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              recomendacao.detalhe,
              style: const TextStyle(
                color: AppColors.textoEscuro,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
          if (recomendacao.dicas.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDicas(),
          ],
        ],
      ),
    );
  }

  Widget _buildDicas() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.add_circle, size: 20, color: AppColors.verde),
              SizedBox(width: 8),
              Text(
                'Dicas extras',
                style: TextStyle(
                  color: AppColors.textoEscuro,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          for (final dica in recomendacao.dicas)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 20, color: AppColors.verde),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dica,
                      style: const TextStyle(
                        color: AppColors.textoEscuro,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
