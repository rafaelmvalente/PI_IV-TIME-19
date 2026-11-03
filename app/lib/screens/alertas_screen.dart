// Caique Vasconcelos Naimi - 25004208
// Data: 28/10/2026
// Descrição: Tela 5 do relatório — lista de todos os alertas recebidos, com
// filtro por tipo (Todos, Geada, Seca, Chuva). Tocar em um alerta abre o detalhe.

import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../theme/app_colors.dart';
import '../widgets/alerta_visual.dart';
import 'detalhe_alerta_screen.dart';

// StatefulWidget porque a tela muda enquanto está aberta: o filtro escolhido
// e o resultado do carregamento dos alertas.
class AlertasScreen extends StatefulWidget {
  // Quem abre a tela decide de onde vêm os alertas. No app é o AlertaService,
  // que usa alertas de exemplo até o backend existir (P010).
  const AlertasScreen({super.key, required this.carregarAlertas});

  final Future<List<Alerta>> Function() carregarAlertas;

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  // "late" avisa que a variável recebe valor depois (no initState), mas
  // antes de ser usada.
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
                  // Sem seta de voltar: a tela é uma aba da navegação.
                  const Text(
                    'Alertas',
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

  Widget _buildLista() {
    // FutureBuilder redesenha a lista conforme o carregamento anda:
    // carregando -> erro ou dados. Cada caso tem sua própria tela.
    return FutureBuilder<List<Alerta>>(
      future: _alertas,
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
                'Não foi possível carregar os alertas.\n'
                'Verifique sua conexão e tente de novo.',
            botao: 'Tentar de novo',
            aoTocar: () => setState(_carregar),
          );
        }

        // O filtro é aplicado nos alertas já carregados, sem buscar de novo.
        final alertas = snapshot.data!
            .where((a) => _filtro == null || a.tipo == _filtro)
            .toList();

        if (alertas.isEmpty) {
          return MensagemAlertas(
            icone: Icons.notifications_off_outlined,
            texto: _filtro == null
                ? 'Nenhum alerta por enquanto.'
                : 'Nenhum alerta de ${_filtro!.rotulo.toLowerCase()}.',
          );
        }

        // ListView.separated monta só os itens visíveis e coloca um espaço
        // entre um cartão e outro.
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
    // Material + InkWell: o cartão inteiro vira clicável e mostra o efeito
    // de toque (ondulação) por cima do fundo branco.
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
