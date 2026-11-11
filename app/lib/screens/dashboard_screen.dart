// Rafael Mendes Valente - 25002875
// Data: 28/10/26
// Horário: 5h - 11h
// Descrição: Tela de início (dashboard) do aplicativo ClimAlerta. Mostra a
// saudação ao produtor e a propriedade, o clima de hoje, o alerta em destaque
// e a lista dos próximos alertas previstos, além da barra de navegação
// inferior, que troca entre as abas Início, Alertas, Histórico e Perfil.
// Consulta a previsão, os alertas, o histórico e o perfil no backend.
// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Carrega clima e alertas reais da propriedade pela API.

import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../models/clima.dart';
import '../models/propriedade.dart';
import '../services/alerta_service.dart';
import '../services/clima_service.dart';
import '../session/sessao.dart';
import '../widgets/alerta_visual.dart';
import 'alertas_screen.dart';
import 'detalhe_alerta_screen.dart';
import 'historico_screen.dart';
import 'modo_offline_screen.dart';
import 'perfil_screen.dart';

class DashboardScreen extends StatefulWidget {
  // A propriedade pode ser nula quando o produtor ainda não cadastrou nenhuma.
  const DashboardScreen({
    super.key,
    this.propriedade,
    this.carregarAlertas,
    this.carregarHistorico,
    this.carregarPrevisao,
    this.atualizarStatusAlerta,
  });

  final Propriedade? propriedade;
  final Future<List<Alerta>> Function(String propriedadeId)? carregarAlertas;
  final Future<List<Alerta>> Function(String propriedadeId)? carregarHistorico;
  final Future<PrevisaoClimatica> Function(String propriedadeId)?
  carregarPrevisao;
  final Future<Alerta> Function(Alerta alerta, StatusAlerta status)?
  atualizarStatusAlerta;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color _verde = Color(0xFF1E7B58);
  static const Color _textoEscuro = Color(0xFF1F2D27);
  static const Color _textoSuave = Color(0xFF6B7A73);

  // Posições das abas na barra de navegação.
  static const int _abaInicio = 0;
  static const int _abaAlertas = 1;
  static const int _abaHistorico = 2;
  static const int _abaPerfil = 3;

  int _aba = _abaInicio;

  String? _propriedadeCarregada;
  String? _propriedadeIdAtual;
  Future<List<Alerta>> _alertas = Future.value(const <Alerta>[]);
  Future<PrevisaoClimatica>? _previsao;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final propriedadeId =
        SessaoScope.of(context).propriedade?.id ?? widget.propriedade?.id;
    if (_propriedadeCarregada == propriedadeId) return;

    _propriedadeCarregada = propriedadeId;
    _propriedadeIdAtual = propriedadeId;
    if (propriedadeId == null) {
      _alertas = Future.value(const <Alerta>[]);
      _previsao = null;
    } else {
      _alertas =
          widget.carregarAlertas?.call(propriedadeId) ??
          AlertaService().listar(propriedadeId);
      _previsao =
          widget.carregarPrevisao?.call(propriedadeId) ??
          const ClimaService().previsao(propriedadeId);
    }
  }

  void _recarregarDados() {
    final id = _propriedadeIdAtual;
    if (id == null) return;
    setState(() {
      _alertas = widget.carregarAlertas?.call(id) ?? AlertaService().listar(id);
      _previsao =
          widget.carregarPrevisao?.call(id) ??
          const ClimaService().previsao(id);
    });
  }

  void _irPara(int aba) => setState(() => _aba = aba);

  void _abrirDetalhe(Alerta alerta) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalheAlertaScreen(
          alerta: alerta,
          atualizarStatus: widget.atualizarStatusAlerta == null
              ? null
              : (status) => widget.atualizarStatusAlerta!(alerta, status),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // AvisoModoOffline abre a tela 10 quando o aparelho fica sem internet.
    return AvisoModoOffline(child: _buildTela());
  }

  Widget _buildTela() {
    final propriedadeId =
        SessaoScope.of(context).propriedade?.id ?? widget.propriedade?.id;
    // Cada aba é montada só quando aparece; assim Alertas e Histórico
    // buscam os dados de novo toda vez que o produtor volta para elas.
    final conteudo = switch (_aba) {
      _abaAlertas => AlertasScreen(
        atualizarStatus: widget.atualizarStatusAlerta,
        carregarAlertas: () {
          if (propriedadeId == null) return Future.value(<Alerta>[]);
          return widget.carregarAlertas?.call(propriedadeId) ??
              AlertaService().listar(propriedadeId);
        },
      ),
      _abaHistorico => HistoricoScreen(
        propriedadeId: propriedadeId ?? '',
        carregarHistorico:
            propriedadeId == null || widget.carregarHistorico == null
            ? null
            : () => widget.carregarHistorico!(propriedadeId),
      ),
      _abaPerfil => const PerfilScreen(),
      _ => _buildInicio(),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: Center(
        // Limita a largura na web, simulando um celular.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          // A tela é uma Column com duas partes: o conteúdo da aba (Expanded,
          // que ocupa todo o espaço que sobra) e a barra de navegação, que
          // fica fixa embaixo.
          child: Column(
            children: [
              Expanded(child: conteudo),
              _BarraNavegacao(indice: _aba, aoTocar: _irPara),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInicio() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: FutureBuilder<List<Alerta>>(
          future: _alertas,
          builder: (context, snapshot) {
            // Enquanto carrega (ou se der erro) a lista fica vazia, e o
            // resto da tela aparece normalmente.
            final alertas = snapshot.data ?? const <Alerta>[];
            // O destaque é o primeiro alerta de risco alto; se não houver,
            // o mais próximo.
            final destaque = alertas.isEmpty
                ? null
                : alertas.firstWhere(
                    (a) => a.nivel == NivelRisco.alto,
                    orElse: () => alertas.first,
                  );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCabecalho(),
                const SizedBox(height: 18),
                _buildClima(),
                if (destaque != null) ...[
                  const SizedBox(height: 14),
                  _buildAlertaDestaque(destaque),
                ],
                const SizedBox(height: 22),
                _buildProximosAlertas(
                  alertas,
                  carregando: snapshot.connectionState != ConnectionState.done,
                  erro: snapshot.hasError,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Estilo de "cartão branco" usado no clima e na lista de alertas.
  BoxDecoration _estiloCartao() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildCabecalho() {
    // "??" usa o valor da esquerda se ele existir; se for null, usa o da
    // direita. A sessão vem primeiro porque guarda a propriedade editada no
    // Perfil; depois a recebida ao abrir a tela; por fim o nome de exemplo.
    final nomePropriedade =
        SessaoScope.of(context).propriedade?.nome ??
        widget.propriedade?.nome ??
        'Nenhuma propriedade cadastrada';
    final nomeProdutor = SessaoScope.of(context).nome;

    return Row(
      children: [
        // Expanded faz o texto ocupar o espaço livre e empurra o sino e o
        // avatar para a direita.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nomeProdutor == null || nomeProdutor.isEmpty
                    ? 'Olá!'
                    : 'Olá, $nomeProdutor!',
                style: TextStyle(
                  color: _textoEscuro,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: _textoSuave,
                  ),
                  const SizedBox(width: 4),
                  // Flexible evita que um nome grande estoure a tela: o
                  // texto é cortado com "..." quando não cabe.
                  Flexible(
                    child: Text(
                      nomePropriedade,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _textoSuave, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Alertas',
          onPressed: () => _irPara(_abaAlertas),
          icon: const Icon(Icons.notifications_none, color: _textoEscuro),
        ),
        // O avatar leva ao Perfil. Semantics avisa ao leitor de tela que é
        // um botão.
        Semantics(
          button: true,
          label: 'Perfil',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _irPara(_abaPerfil),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: _verde,
              child: Icon(Icons.person, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClima() {
    final future = _previsao;
    if (future == null) {
      return _buildClimaHoje(null);
    }
    return FutureBuilder<PrevisaoClimatica>(
      future: future,
      builder: (context, snapshot) {
        final forecast = snapshot.data;
        if (forecast == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildClimaHoje(
                null,
                carregando: !snapshot.hasData && !snapshot.hasError,
              ),
              if (snapshot.hasError) ...[
                const SizedBox(height: 8),
                const Text(
                  'Não foi possível carregar a previsão completa.',
                  style: TextStyle(color: _textoSuave, fontSize: 13),
                ),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildClimaHoje(forecast.atual),
            const SizedBox(height: 12),
            _buildPrevisao(forecast.dias),
          ],
        );
      },
    );
  }

  Widget _buildPrevisao(List<ClimaDia> dias) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Previsão dos próximos dias',
          style: TextStyle(
            color: _textoEscuro,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dias.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final dia = dias[index];
              return Container(
                width: 104,
                padding: const EdgeInsets.all(10),
                decoration: _estiloCartao(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${dia.data.day.toString().padLeft(2, '0')}/'
                      '${dia.data.month.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: _textoEscuro,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${dia.maxima.toStringAsFixed(0)}° / '
                      '${dia.minima.toStringAsFixed(0)}°',
                      style: const TextStyle(color: _textoEscuro),
                    ),
                    Text(
                      '${dia.precipitacao.toStringAsFixed(0)} mm',
                      style: const TextStyle(color: _textoSuave, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClimaHoje(ClimaHoje? clima, {bool carregando = false}) {
    final temperatura = clima?.temperatura.toStringAsFixed(0) ?? '--';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _estiloCartao(),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny, size: 52, color: Color(0xFFF5A623)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hoje',
                  style: TextStyle(color: _textoSuave, fontSize: 13),
                ),
                Text.rich(
                  TextSpan(
                    text: carregando ? '...' : temperatura,
                    style: const TextStyle(
                      color: _textoEscuro,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                    children: const [
                      TextSpan(text: '°C', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                Text(
                  clima?.descricao ??
                      (carregando
                          ? 'Carregando previsão...'
                          : 'Previsão indisponível'),
                  style: const TextStyle(color: _textoSuave, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Máx.: ${clima?.maxima.toStringAsFixed(0) ?? '--'}°',
                style: TextStyle(color: _textoEscuro, fontSize: 13),
              ),
              SizedBox(height: 6),
              Text(
                'Mín.: ${clima?.minima.toStringAsFixed(0) ?? '--'}°',
                style: TextStyle(color: _textoEscuro, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertaDestaque(Alerta alerta) {
    // InkWell dá o efeito de toque (ondulação) e permite clicar no cartão
    // inteiro. O Material por baixo é necessário para a ondulação aparecer
    // por cima da cor de fundo.
    return Material(
      color: const Color(0xFFFFF4E0),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirDetalhe(alerta),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF3D9A4)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE08A00),
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alerta de ${alerta.tipo.rotulo.toLowerCase()}',
                      style: const TextStyle(
                        color: Color(0xFF8A5300),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Risco ${alerta.nivel.rotulo.toLowerCase()} · '
                      '${formatarQuando(alerta.previstoPara)}',
                      style: const TextStyle(
                        color: Color(0xFF8A5300),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF8A5300)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProximosAlertas(
    List<Alerta> alertas, {
    required bool carregando,
    required bool erro,
  }) {
    // Mostra só os três mais próximos; o resto fica na aba Alertas.
    final proximos = alertas.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Flexible: em telas estreitas o título quebra a linha em vez de
            // empurrar o "Ver todos" para fora.
            const Flexible(
              child: Text(
                'Próximos alertas',
                style: TextStyle(
                  color: _textoEscuro,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _irPara(_abaAlertas),
              child: const Text(
                'Ver todos',
                style: TextStyle(color: _verde, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: _estiloCartao(),
          child: Column(
            children: [
              if (carregando)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: _verde),
                )
              else if (proximos.isEmpty && !erro)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Nenhum alerta previsto.',
                    style: TextStyle(color: _textoSuave, fontSize: 14),
                  ),
                ),
              if (erro)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextButton.icon(
                    onPressed: _recarregarDados,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar carregar alertas novamente'),
                  ),
                ),
              // "collection for": monta um item para cada alerta da lista, sem
              // repetir código. O "if" dentro da lista coloca a linha
              // divisória entre os itens, menos depois do último.
              for (int i = 0; i < proximos.length; i++) ...[
                _ItemAlerta(
                  alerta: proximos[i],
                  aoTocar: () => _abrirDetalhe(proximos[i]),
                ),
                if (i < proximos.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// Uma linha da lista de próximos alertas. Fica em uma classe própria para
// que cada item seja montado a partir de um Alerta.
class _ItemAlerta extends StatelessWidget {
  final Alerta alerta;
  final VoidCallback aoTocar;

  const _ItemAlerta({required this.alerta, required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconeAlerta(tipo: alerta.tipo, raio: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerta.tipo.rotulo,
                    style: const TextStyle(
                      color: Color(0xFF1F2D27),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatarQuando(alerta.previstoPara),
                    style: const TextStyle(
                      color: Color(0xFF6B7A73),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9AA7A0)),
          ],
        ),
      ),
    );
  }
}

// Barra de navegação inferior (Início, Alertas, Histórico e Perfil). Avisa a
// tela qual aba foi tocada, e a tela troca o conteúdo.
class _BarraNavegacao extends StatelessWidget {
  const _BarraNavegacao({required this.indice, required this.aoTocar});

  final int indice;
  final ValueChanged<int> aoTocar;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: indice,
      // "fixed" mantém os quatro itens sempre com o texto visível.
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF1E7B58),
      unselectedItemColor: const Color(0xFF8A9690),
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: aoTocar,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none),
          activeIcon: Icon(Icons.notifications),
          label: 'Alertas',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
