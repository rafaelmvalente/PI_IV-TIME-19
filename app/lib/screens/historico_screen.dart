// Caique Vasconcelos Naimi - 25004208
// Data: 03/11/2026
// Descrição: Tela 8 do relatório — histórico de todos os alertas recebidos,
// agrupados por mês, com o status de cada um (Em andamento, Ação realizada,
// Resolvido) e filtro por tipo. Tocar em um alerta abre o detalhe.
// Data: 11/11/2026
// Descrição: Consulta o histórico da propriedade escolhida no dashboard.

import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../services/alerta_service.dart';
import '../theme/app_colors.dart';
import '../widgets/alerta_visual.dart';
import 'detalhe_alerta_screen.dart';

class HistoricoScreen extends StatefulWidget {
  // Quem abre a tela pode trocar de onde vem o histórico (útil nos testes).
  // Sem informar, usa o AlertaService.
  const HistoricoScreen({
    super.key,
    this.carregarHistorico,
    this.propriedadeId = '',
  });

  final Future<List<Alerta>> Function()? carregarHistorico;
  final String propriedadeId;

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  static const _meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  late Future<List<Alerta>> _historico;
  TipoAlerta? _filtro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    final carregar =
        widget.carregarHistorico ??
        () => AlertaService().listarHistorico(widget.propriedadeId);
    // Future.sync: um erro lançado na hora vira um Future com erro, e o
    // FutureBuilder mostra a mensagem em vez de quebrar a tela.
    _historico = Future.sync(carregar);
  }

  Future<void> _abrirDetalhe(Alerta alerta) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetalheAlertaScreen(alerta: alerta)),
    );
    // O status pode ter mudado no detalhe, então busca de novo ao voltar.
    if (mounted) setState(_carregar);
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Histórico',
                    style: TextStyle(
                      color: AppColors.textoEscuro,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FiltroTipoAlerta(
                    selecionado: _filtro,
                    aoMudar: (tipo) => setState(() => _filtro = tipo),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _buildLista()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLista() {
    return FutureBuilder<List<Alerta>>(
      future: _historico,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.verde),
          );
        }

        if (snapshot.hasError) {
          return MensagemAlertas(
            icone: Icons.cloud_off,
            texto:
                'Não foi possível carregar o histórico.\n'
                'Verifique sua conexão e tente de novo.',
            botao: 'Tentar de novo',
            aoTocar: () => setState(_carregar),
          );
        }

        final alertas = snapshot.data!
            .where((a) => _filtro == null || a.tipo == _filtro)
            .toList();

        if (alertas.isEmpty) {
          return MensagemAlertas(
            icone: Icons.history,
            texto: _filtro == null
                ? 'Nenhum alerta no histórico ainda.'
                : 'Nenhum alerta de ${_filtro!.rotulo.toLowerCase()} no histórico.',
          );
        }

        // Os alertas já chegam do mais recente para o mais antigo; aqui é só
        // colocar o nome do mês antes do primeiro alerta de cada mês.
        final itens = <Widget>[];
        String? mesAnterior;
        for (final alerta in alertas) {
          final data = alerta.previstoPara;
          final mes = '${_meses[data.month - 1]} de ${data.year}';
          if (mes != mesAnterior) {
            itens.add(_TituloMes(texto: mes));
            mesAnterior = mes;
          }
          itens.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CartaoHistorico(
                alerta: alerta,
                aoTocar: () => _abrirDetalhe(alerta),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: itens,
        );
      },
    );
  }
}

class _TituloMes extends StatelessWidget {
  const _TituloMes({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(
          color: AppColors.textoSecundario,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CartaoHistorico extends StatelessWidget {
  const _CartaoHistorico({required this.alerta, required this.aoTocar});

  final Alerta alerta;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconeAlerta(tipo: alerta.tipo),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tituloDoAlerta(alerta.tipo),
                      style: const TextStyle(
                        color: AppColors.textoEscuro,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatarQuando(alerta.previstoPara),
                      style: const TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SeloStatus(status: alerta.status),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9AA7A0)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeloStatus extends StatelessWidget {
  const _SeloStatus({required this.status});

  final StatusAlerta status;

  @override
  Widget build(BuildContext context) {
    // Amarelo enquanto o risco está em curso, azul quando o produtor já agiu
    // e verde quando o risco acabou.
    final (fundo, texto) = switch (status) {
      StatusAlerta.emAndamento => (
        const Color(0xFFFFF1CC),
        const Color(0xFF8A5300),
      ),
      StatusAlerta.acaoRealizada => (
        const Color(0xFFE3F0FB),
        const Color(0xFF1F5F99),
      ),
      StatusAlerta.resolvido => (
        const Color(0xFFE3F3E8),
        const Color(0xFF1E7B58),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.rotulo,
        semanticsLabel: 'Status: ${status.rotulo}',
        style: TextStyle(
          color: texto,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
