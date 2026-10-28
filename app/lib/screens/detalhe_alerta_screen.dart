// Caique Vasconcelos Naimi - 25004208
// Data: 28/10/2026
// Descrição: Tela 6 do relatório — detalhe do alerta: risco, nível de
// severidade, explicação e a ação prática sugerida. Pelo menu "..." o produtor
// marca o status do alerta (Em andamento / Ação realizada / Resolvido).

import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../services/alerta_service.dart';
import '../theme/app_colors.dart';
import '../widgets/alerta_visual.dart';
import 'recomendacoes_screen.dart';

class DetalheAlertaScreen extends StatefulWidget {
  const DetalheAlertaScreen({
    super.key,
    required this.alerta,
    this.atualizarStatus,
  });

  final Alerta alerta;

  // Salva o novo status e devolve o alerta atualizado. Se não for informado,
  // usa o AlertaService, que ainda depende do backend (TODO(P010)).
  final Future<Alerta> Function(StatusAlerta status)? atualizarStatus;

  @override
  State<DetalheAlertaScreen> createState() => _DetalheAlertaScreenState();
}

class _DetalheAlertaScreenState extends State<DetalheAlertaScreen> {
  // Cópia local do alerta: quando o status muda, a tela troca este valor e
  // se redesenha sem precisar ser aberta de novo.
  late Alerta _alerta = widget.alerta;

  Future<void> _mudarStatus(StatusAlerta status) async {
    final salvar =
        widget.atualizarStatus ??
        (s) => const AlertaService().atualizarStatus(_alerta.id, s);

    // try/catch: se o salvamento falhar (hoje sempre falha, pois não há
    // backend), o produtor vê uma mensagem em vez de o app travar.
    try {
      final atualizado = await Future.sync(() => salvar(status));
      // "mounted" confere se a tela ainda está aberta depois da espera.
      if (!mounted) return;
      setState(() => _alerta = atualizado);
      _mostrarMensagem('Status atualizado: ${atualizado.status.rotulo}');
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível atualizar o status agora.');
    }
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

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
                  Row(
                    children: [
                      const BackButton(),
                      const Spacer(),
                      // Menu "..." do protótipo: lista os status e marca com
                      // um check o status atual do alerta.
                      PopupMenuButton<StatusAlerta>(
                        icon: const Icon(Icons.more_horiz),
                        tooltip: 'Marcar status do alerta',
                        onSelected: _mudarStatus,
                        itemBuilder: (_) => [
                          for (final status in StatusAlerta.values)
                            CheckedPopupMenuItem(
                              value: status,
                              checked: status == _alerta.status,
                              child: Text(status.rotulo),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          _buildCartaoRisco(),
                          const SizedBox(height: 16),
                          _buildRecomendacao(),
                        ],
                      ),
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
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecomendacoesScreen(
                              recomendacao: _alerta.recomendacao,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Ver outras orientações',
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

  Widget _buildCartaoRisco() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconeAlerta(tipo: _alerta.tipo, raio: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tituloDoAlerta(_alerta.tipo),
                      style: const TextStyle(
                        color: AppColors.textoEscuro,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatarQuando(_alerta.previstoPara),
                      style: const TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${_alerta.status.rotulo}',
                      style: const TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _SeloNivel(nivel: _alerta.nivel),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _alerta.descricao,
              style: const TextStyle(
                color: AppColors.textoEscuro,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecomendacao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 34,
            color: AppColors.textoEscuro,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recomendação',
                  style: TextStyle(
                    color: AppColors.textoEscuro,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                // Junta a ação e o detalhe numa frase só, como no protótipo
                // ("Proteja as mudas. Cubra as plantas...").
                Text(
                  [
                    _alerta.recomendacao.acao,
                    _alerta.recomendacao.detalhe,
                  ].where((t) => t.isNotEmpty).join('. '),
                  style: const TextStyle(
                    color: AppColors.textoEscuro,
                    fontSize: 15,
                    height: 1.4,
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

class _SeloNivel extends StatelessWidget {
  const _SeloNivel({required this.nivel});

  final NivelRisco nivel;

  @override
  Widget build(BuildContext context) {
    // O switch devolve as duas cores de uma vez: risco alto em vermelho e
    // médio em amarelo.
    final (fundo, texto) = switch (nivel) {
      NivelRisco.alto => (const Color(0xFFFDE2E2), const Color(0xFFC62828)),
      NivelRisco.medio => (const Color(0xFFFFF1CC), const Color(0xFF8A5300)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        nivel.rotulo,
        semanticsLabel: 'Risco ${nivel.rotulo}',
        style: TextStyle(
          color: texto,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
