// Data: 28/10/2026
// Descrição: Tela 5 do relatório — lista de todos os alertas recebidos, com
// filtro por tipo (Todos, Geada, Seca, Chuva). Tocar em um alerta abre o detalhe.

import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../theme/app_colors.dart';
import '../widgets/alerta_visual.dart';
import 'detalhe_alerta_screen.dart';

class AlertasScreen extends StatefulWidget {
  // Quem abre a tela decide de onde vêm os alertas. Hoje é o AlertaService,
  // que ainda depende do backend (TODO(P010)).
  const AlertasScreen({super.key, required this.carregarAlertas});

  final Future<List<Alerta>> Function() carregarAlertas;

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  static const _filtros = <(TipoAlerta?, String)>[
    (null, 'Todos'),
    (TipoAlerta.geada, 'Geada'),
    (TipoAlerta.seca, 'Seca'),
    (TipoAlerta.chuvaForte, 'Chuva'),
  ];

  late Future<List<Alerta>> _alertas;
  TipoAlerta? _filtro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    // Future.sync transforma um erro lançado na hora em um Future com erro,
    // para que o FutureBuilder mostre a mensagem em vez de quebrar a tela.
    _alertas = Future.sync(widget.carregarAlertas);
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
                  Row(
                    children: [
                      if (Navigator.of(context).canPop()) const BackButton(),
                      const Text(
                        'Alertas',
                        style: TextStyle(
                          color: AppColors.textoEscuro,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFiltros(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildLista()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (tipo, rotulo) in _filtros)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(rotulo),
                selected: _filtro == tipo,
                showCheckmark: false,
                selectedColor: AppColors.verde,
                backgroundColor: const Color(0xFFE6EBE8),
                side: BorderSide.none,
                shape: const StadiumBorder(),
                labelStyle: TextStyle(
                  color: _filtro == tipo ? Colors.white : AppColors.textoEscuro,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _filtro = tipo),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return FutureBuilder<List<Alerta>>(
      future: _alertas,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.verde),
          );
        }

        if (snapshot.hasError) {
          return _Mensagem(
            icone: Icons.cloud_off,
            texto: 'Não foi possível carregar os alertas.\n'
                'Verifique sua conexão e tente de novo.',
            botao: 'Tentar de novo',
            aoTocar: () => setState(_carregar),
          );
        }

        final alertas = snapshot.data!
            .where((a) => _filtro == null || a.tipo == _filtro)
            .toList();

        if (alertas.isEmpty) {
          return _Mensagem(
            icone: Icons.notifications_off_outlined,
            texto: _filtro == null
                ? 'Nenhum alerta por enquanto.'
                : 'Nenhum alerta de ${_filtro!.rotulo.toLowerCase()}.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: alertas.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _CartaoAlerta(alerta: alertas[i]),
        );
      },
    );
  }
}

class _CartaoAlerta extends StatelessWidget {
  const _CartaoAlerta({required this.alerta});

  final Alerta alerta;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetalheAlertaScreen(alerta: alerta),
          ),
        ),
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

// Mensagem centralizada para os estados de vazio e de erro.
class _Mensagem extends StatelessWidget {
  const _Mensagem({
    required this.icone,
    required this.texto,
    this.botao,
    this.aoTocar,
  });

  final IconData icone;
  final String texto;
  final String? botao;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 56, color: AppColors.textoSecundario),
          const SizedBox(height: 12),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textoEscuro, fontSize: 16),
          ),
          if (botao != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.verde,
                side: const BorderSide(color: AppColors.verde),
              ),
              onPressed: aoTocar,
              child: Text(botao!),
            ),
          ],
        ],
      ),
    );
  }
}
