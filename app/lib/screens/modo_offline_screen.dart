// Vinicius Santuci Virgolino - 25000294
// Data: 28/10/2026
// Descrição: Tela 10 do relatório — avisa que o aparelho está sem internet e
// que os alertas críticos continuarão chegando por SMS. Usa a imagem
// offline_fundo.jpg como fundo e o botão "Entendi" fecha a tela. O
// AvisoModoOffline abre esta tela sozinho quando a conexão cai.

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/armazenamento_local_service.dart';
import '../theme/app_colors.dart';

// Envolve uma tela (ex.: o Dashboard) e abre o ModoOfflineScreen quando o
// aparelho fica sem internet. Se a conexão voltar com o aviso aberto, ele
// fecha sozinho.
class AvisoModoOffline extends StatefulWidget {
  const AvisoModoOffline({
    super.key,
    required this.child,
    this.servico = const ArmazenamentoLocalService(),
  });

  final Widget child;
  final ArmazenamentoLocalService servico;

  @override
  State<AvisoModoOffline> createState() => _AvisoModoOfflineState();
}

class _AvisoModoOfflineState extends State<AvisoModoOffline> {
  StreamSubscription<bool>? _inscricao;
  bool _avisoAberto = false;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    // Erros aqui (ex.: plugin indisponível em testes) não podem derrubar a
    // tela: sem detecção, o app só deixa de mostrar o aviso.
    try {
      _inscricao = widget.servico.mudancasDeConexao().listen(
        _aoMudarConexao,
        onError: (_) {},
      );
      // O stream só avisa mudanças; o app pode já abrir sem internet.
      if (!await widget.servico.estaOnline()) _aoMudarConexao(false);
    } catch (_) {}
  }

  Future<void> _aoMudarConexao(bool online) async {
    if (!mounted) return;

    if (online) {
      if (_avisoAberto) Navigator.of(context).pop();
      return;
    }

    if (_avisoAberto) return;
    _avisoAberto = true;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ModoOfflineScreen()),
    );
    // Chega aqui quando o aviso fecha ("Entendi", voltar ou conexão voltou).
    _avisoAberto = false;
  }

  @override
  void dispose() {
    _inscricao?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class ModoOfflineScreen extends StatelessWidget {
  const ModoOfflineScreen({super.key});

  // TODO(P043): mostrar o telefone cadastrado e se o SMS está ativo nas
  // PreferenciasAlerta, quando esses dados vierem do backend (P010).
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/offline_fundo.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Escurece o topo da imagem para o texto branco ficar legível.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: Colors.white,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      const Spacer(),
                      const _SinalSemInternet(),
                      const SizedBox(height: 28),
                      const Text(
                        'Modo offline ativado',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Você está sem conexão com a internet.\n'
                        'Os alertas críticos continuarão chegando por SMS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildCartao(context),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartao(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                _IconeSms(),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alertas por SMS',
                        style: TextStyle(
                          color: AppColors.textoEscuro,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Você receberá apenas os alertas mais importantes.',
                        style: TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
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
              // "Entendi" fecha o aviso e volta para a tela anterior.
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text(
                'Entendi',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Barras de sinal com um risco vermelho por cima, indicando "sem internet".
class _SinalSemInternet extends StatelessWidget {
  const _SinalSemInternet();

  // Altura de cada barra, da menor para a maior.
  static const _alturas = [14.0, 22.0, 30.0, 38.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 56,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < _alturas.length; i++)
                Container(
                  width: 8,
                  height: _alturas[i],
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    // As barras mais altas ficam apagadas: sinal fraco.
                    color: i < 2
                        ? Colors.white
                        : AppColors.verdeFolha.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
          Positioned(
            right: 10,
            bottom: 2,
            child: Transform.rotate(
              angle: -0.5,
              child: Container(
                width: 3,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.erro,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Balão de conversa verde com "SMS" escrito dentro.
class _IconeSms extends StatelessWidget {
  const _IconeSms();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFFD3EADB),
        shape: BoxShape.circle,
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.chat_bubble, size: 34, color: AppColors.verde),
          Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              'SMS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
