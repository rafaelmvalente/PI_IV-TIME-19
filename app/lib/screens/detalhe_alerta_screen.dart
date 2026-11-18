// Caique Vasconcelos Naimi - 25004208
// Data: 28/10/2026
// Descrição: Tela 6 do relatório — detalhe do alerta: risco, nível de
// severidade, explicação e a ação prática sugerida. Pelo menu "..." o produtor
// marca o status do alerta (Em andamento / Ação realizada / Resolvido).
// Data: 11/11/2026
// Descrição: Envia a atualização de status do alerta ao backend.
// Caio Ávila Marchi - 25008101
// Data: 18/11/2026
// Descrição: Botão "Ouvir alerta", que lê o alerta e a recomendação em voz alta
// (issue #17). Só aparece quando o produtor ativou a preferência de voz.

import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../services/alerta_service.dart';
import '../services/voz_service.dart';
import '../session/sessao.dart';
import '../theme/app_colors.dart';
import '../widgets/alerta_visual.dart';
import 'recomendacoes_screen.dart';

class DetalheAlertaScreen extends StatefulWidget {
  const DetalheAlertaScreen({
    super.key,
    required this.alerta,
    this.atualizarStatus,
    this.voz,
  });

  final Alerta alerta;

  // Salva o novo status e devolve o alerta atualizado. Se não for informado,
  // usa o AlertaService (hoje com alertas de exemplo, até o backend: P010).
  final Future<Alerta> Function(StatusAlerta status)? atualizarStatus;

  // Quem lê o alerta em voz alta. Se não for informado, usa o VozService de verdade.
  final VozService? voz;

  @override
  State<DetalheAlertaScreen> createState() => _DetalheAlertaScreenState();
}

class _DetalheAlertaScreenState extends State<DetalheAlertaScreen> {
  // Cópia local do alerta: quando o status muda, a tela troca este valor e
  // se redesenha sem precisar ser aberta de novo.
  late Alerta _alerta = widget.alerta;

  // O VozService só é criado na primeira vez que alguém aperta "Ouvir alerta".
  VozService? _voz;
  bool _falando = false;

  Future<void> _alternarVoz() async {
    final voz = _voz ??= widget.voz ?? VozService();
    if (_falando) {
      await voz.parar();
      if (mounted) setState(() => _falando = false);
      return;
    }

    setState(() => _falando = true);
    try {
      await voz.lerAlerta(_alerta);
    } on VozIndisponivelException catch (erro) {
      if (mounted) _mostrarMensagem(erro.mensagem);
    } catch (_) {
      if (mounted) {
        _mostrarMensagem('Não foi possível ler o alerta em voz alta agora.');
      }
    } finally {
      if (mounted) setState(() => _falando = false);
    }
  }

  @override
  void dispose() {
    // Se o produtor sair da tela, a leitura para.
    _voz?.parar();
    super.dispose();
  }

  Future<void> _mudarStatus(StatusAlerta status) async {
    final salvar =
        widget.atualizarStatus ??
        (s) => AlertaService().atualizarStatus(_alerta.id, s);

    // try/catch: se o salvamento falhar (ex.: sem conexão com o
    // servidor), o produtor vê uma mensagem em vez de o app travar.
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
                          // O botão só aparece para quem escolheu receber em voz.
                          if (SessaoScope.maybeOf(context)?.preferencias.voz ??
                              false) ...[
                            const SizedBox(height: 16),
                            _buildBotaoOuvir(),
                          ],
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

  Widget _buildBotaoOuvir() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.verde,
          side: const BorderSide(color: AppColors.verde),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _alternarVoz,
        icon: Icon(
          _falando ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
        ),
        label: Text(
          _falando ? 'Parar áudio' : 'Ouvir alerta',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
