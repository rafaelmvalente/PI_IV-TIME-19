// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 28/10/2026
// Descrição: Tela 10 do relatório — avisa que o aparelho está sem internet,
// que os últimos alertas continuam salvos e que os novos chegam por
// notificação quando a internet voltar. Usa a imagem
// offline_fundo.jpg como fundo e o botão "Entendi" fecha a tela. O
// AvisoModoOffline abre esta tela sozinho quando a conexão cai.

// StreamSubscription: a "inscrição" que escuta as mudanças de conexão.
import 'dart:async';

import 'package:flutter/material.dart';
// rootBundle: lê arquivos de assets (a imagem de fundo) como bytes.
import 'package:flutter/services.dart';

import '../services/armazenamento_local_service.dart';
import '../theme/app_colors.dart';

// Caminho da imagem de fundo (declarada no pubspec.yaml, em assets).
const _caminhoFundo = 'assets/images/offline_fundo.jpg';

// Bytes da imagem de fundo, guardados na memória enquanto ainda há internet.
// Na web cada imagem é baixada do servidor só quando aparece; como a tela 10
// aparece justamente sem internet, ela não conseguiria baixar o fundo.
Uint8List? _bytesFundo;

// Carrega a imagem uma vez só e guarda em _bytesFundo.
Future<void> _guardarFundo() async {
  // Já foi carregada antes: não precisa de novo.
  if (_bytesFundo != null) return;
  try {
    final dados = await rootBundle.load(_caminhoFundo);
    _bytesFundo = dados.buffer.asUint8List();
  } catch (_) {
    // Se não carregar, tudo bem: a tela usa o fundo verde no lugar.
  }
}

// Envolve uma tela (ex.: o Dashboard) e abre o ModoOfflineScreen quando o
// aparelho fica sem internet. Se a conexão voltar com o aviso aberto, ele
// fecha sozinho.
// Não desenha nada próprio: só mostra a tela de dentro (child) e fica
// "ouvindo" a conexão por trás.
class AvisoModoOffline extends StatefulWidget {
  const AvisoModoOffline({
    super.key,
    required this.child,
    this.servico = const ArmazenamentoLocalService(),
    this.aoMudarConexao,
  });

  // A tela envolvida (normalmente o Dashboard).
  final Widget child;
  // Quem informa a conexão. Recebido aqui para os testes simularem a queda.
  final ArmazenamentoLocalService servico;

  // Avisa a tela de dentro (ex.: o Dashboard) quando a conexão cai ou volta,
  // para ela buscar os dados novos assim que a internet voltar.
  final void Function(bool online)? aoMudarConexao;

  @override
  State<AvisoModoOffline> createState() => _AvisoModoOfflineState();
}

class _AvisoModoOfflineState extends State<AvisoModoOffline> {
  // Inscrição no stream de conexão. Guardada para ser cancelada no dispose.
  StreamSubscription<bool>? _inscricao;
  // Evita abrir duas telas de aviso uma em cima da outra.
  bool _avisoAberto = false;

  // initState roda uma vez, quando o widget aparece pela primeira vez.
  @override
  void initState() {
    super.initState();
    // Guarda a imagem de fundo agora, enquanto ainda há internet.
    _guardarFundo();
    // Começa a ouvir a conexão.
    _iniciar();
  }

  Future<void> _iniciar() async {
    // Erros aqui (ex.: plugin indisponível em testes) não podem derrubar a
    // tela: sem detecção, o app só deixa de mostrar o aviso.
    try {
      // Cada mudança de conexão (cai/volta) chama _aoMudarConexao.
      _inscricao = widget.servico.mudancasDeConexao().listen(
        _aoMudarConexao,
        onError: (_) {},
      );
      // O stream só avisa mudanças; o app pode já abrir sem internet.
      if (!await widget.servico.estaOnline()) _aoMudarConexao(false);
    } catch (_) {}
  }

  // Reage à queda ou à volta da internet.
  Future<void> _aoMudarConexao(bool online) async {
    // A tela já foi fechada: não há onde abrir o aviso.
    if (!mounted) return;
    // Repassa a novidade para a tela de dentro (o Dashboard recarrega).
    widget.aoMudarConexao?.call(online);

    // Internet voltou: fecha o aviso, se ele estiver aberto.
    if (online) {
      if (_avisoAberto) Navigator.of(context).pop();
      return;
    }

    // Internet caiu: abre o aviso (só se ainda não estiver aberto).
    if (_avisoAberto) return;
    _avisoAberto = true;
    // O "await" espera até a tela de aviso ser fechada.
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ModoOfflineScreen()));
    // Chega aqui quando o aviso fecha ("Entendi", voltar ou conexão voltou).
    _avisoAberto = false;
  }

  // Ao sair da tela, para de ouvir a conexão (senão continuaria rodando).
  @override
  void dispose() {
    _inscricao?.cancel();
    super.dispose();
  }

  // Mostra a tela envolvida sem mudar nada nela.
  @override
  Widget build(BuildContext context) => widget.child;
}

// A tela de aviso em si (Tela 10 do relatório).
// StatelessWidget: só mostra textos, não guarda estado.
class ModoOfflineScreen extends StatelessWidget {
  const ModoOfflineScreen({super.key, this.semConexao = true});

  // true: aberta pelo AvisoModoOffline, porque a internet caiu.
  // false: aberta pelo Perfil só para explicar como funciona sem internet.
  final bool semConexao;

  // O título e o texto mudam conforme o motivo de a tela ter sido aberta.
  String get _titulo =>
      semConexao ? 'Modo offline ativado' : 'Como funciona sem internet';

  String get _texto => semConexao
      ? 'Você está sem conexão com a internet.\n'
            'Os alertas chegam por notificação quando a internet voltar.'
      : 'Quando você ficar sem conexão com a internet, os alertas chegam '
            'por notificação quando ela voltar.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Stack: camadas empilhadas, da de baixo para a de cima:
      // 1) foto de fundo, 2) sombra escura, 3) conteúdo.
      body: Stack(
        children: [
          // 1) Foto de fundo ocupando a tela toda.
          Positioned.fill(child: _buildFundo()),
          // 2) Escurece o topo da imagem para o texto branco ficar legível.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Degradê de cima (35% preto) para baixo (15% preto).
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
          // 3) Conteúdo: seta de voltar, ícone, textos e cartão.
          SafeArea(
            child: Center(
              // Largura máxima de 430 para não esticar em telas grandes.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      // Seta de voltar branca no canto esquerdo.
                      // maybePop: só volta se houver tela anterior.
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: Colors.white,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      // Os dois Spacer (aqui e no fim) centralizam o conteúdo
                      // na altura da tela.
                      const Spacer(),
                      // Desenho das barras de sinal riscadas.
                      const _SinalSemInternet(),
                      const SizedBox(height: 28),
                      // Título grande ("Modo offline ativado").
                      Text(
                        _titulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Explicação do que acontece sem internet.
                      Text(
                        _texto,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Cartão branco com "Últimos alertas salvos" e "Entendi".
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

  // Monta a imagem de fundo.
  Widget _buildFundo() {
    // Se a imagem não carregar, mostra um fundo verde liso no lugar da
    // mensagem de erro.
    // Os três "_" são parâmetros que o errorBuilder recebe mas não usamos.
    Widget fundoVerde(BuildContext _, Object _, StackTrace? _) =>
        const ColoredBox(color: AppColors.verde);

    // Usa os bytes guardados pelo AvisoModoOffline; se não houver (ex.: tela
    // aberta pelo Perfil ou pela prévia, com internet), carrega normalmente.
    final bytes = _bytesFundo;
    if (bytes != null) {
      // BoxFit.cover: a foto cobre a tela toda, cortando as sobras.
      return Image.memory(bytes, fit: BoxFit.cover, errorBuilder: fundoVerde);
    }
    return Image.asset(
      _caminhoFundo,
      fit: BoxFit.cover,
      errorBuilder: fundoVerde,
    );
  }

  // Cartão branco da parte de baixo: lembra que os últimos dados continuam
  // disponíveis e tem o botão "Entendi".
  Widget _buildCartao(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Faixa verde-clara com o ícone de histórico e o texto.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Círculo verde com o ícone de relógio (histórico).
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD3EADB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history,
                    size: 30,
                    color: AppColors.verde,
                  ),
                ),
                const SizedBox(width: 14),
                // Título e explicação ocupando o resto da linha.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Últimos alertas salvos',
                        style: TextStyle(
                          color: AppColors.textoEscuro,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Você continua vendo os alertas e o clima da última '
                        'atualização.',
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
          // Botão verde de largura total.
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
// Desenhado com widgets simples (Containers), sem precisar de imagem.
class _SinalSemInternet extends StatelessWidget {
  const _SinalSemInternet();

  // Altura de cada barra, da menor para a maior.
  static const _alturas = [14.0, 22.0, 30.0, 38.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 56,
      // Stack: o risco vermelho fica por cima das barras.
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // As 4 barras lado a lado, alinhadas pela base (crossAxis end).
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Cria uma barra para cada altura da lista.
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
          // Risco vermelho inclinado por cima das barras.
          Positioned(
            right: 10,
            bottom: 2,
            child: Transform.rotate(
              // Ângulo em radianos (-0.5 ≈ -29 graus).
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
