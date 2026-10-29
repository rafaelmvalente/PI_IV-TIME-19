// Rafael Mendes Valente - 25002875
// Data: 28/10/26
// Horário: 5h - 11h
// Descrição: Tela de início (dashboard) do aplicativo ClimAlerta. Mostra a
// saudação ao produtor e a propriedade, o clima de hoje, o alerta em destaque
// e a lista dos próximos alertas previstos, além da barra de navegação
// inferior. Os dados são fixos (exemplo) até a integração com o servidor.

import 'package:flutter/material.dart';

import '../models/propriedade.dart';
import 'modo_offline_screen.dart';

// Modelo simples para um alerta da lista. Guardar os dados em uma classe
// separa "o que mostrar" de "como mostrar", e facilita trocar os dados fixos
// pelos dados do servidor depois.
class _Alerta {
  final String titulo;
  final String quando;
  final IconData icone;
  final Color corIcone;
  final Color corFundo;

  const _Alerta({
    required this.titulo,
    required this.quando,
    required this.icone,
    required this.corIcone,
    required this.corFundo,
  });
}

class DashboardScreen extends StatelessWidget {
  // A propriedade é opcional (?) porque o dashboard também abre pelo login,
  // onde ainda não há propriedade cadastrada. Nesse caso, mostra o nome de
  // exemplo.
  const DashboardScreen({super.key, this.propriedade});

  final Propriedade? propriedade;

  static const Color _verde = Color(0xFF1E7B58);
  static const Color _textoEscuro = Color(0xFF1F2D27);
  static const Color _textoSuave = Color(0xFF6B7A73);

  // Dados de exemplo, iguais aos do protótipo.
  static const List<_Alerta> _proximos = [
    _Alerta(
      titulo: 'Chuva forte',
      quando: 'Amanhã, 23 de ago · 14:00',
      icone: Icons.water_drop,
      corIcone: Color(0xFF3B82C4),
      corFundo: Color(0xFFE3F0FB),
    ),
    _Alerta(
      titulo: 'Seca prolongada',
      quando: '25 de ago · 10:00',
      icone: Icons.wb_sunny,
      corIcone: Color(0xFFE9A317),
      corFundo: Color(0xFFFFF1CC),
    ),
    _Alerta(
      titulo: 'Geada',
      quando: '28 de ago · 06:00',
      icone: Icons.ac_unit,
      corIcone: Color(0xFF2E8BC0),
      corFundo: Color(0xFFDDF1F8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // AvisoModoOffline abre a tela 10 quando o aparelho fica sem internet.
    return AvisoModoOffline(child: _buildTela());
  }

  Widget _buildTela() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: Center(
        // Limita a largura na web, simulando um celular.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          // A tela é uma Column com duas partes: o conteúdo (Expanded, que
          // ocupa todo o espaço que sobra e rola se for grande demais) e a
          // barra de navegação, que fica fixa embaixo.
          child: Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCabecalho(),
                        const SizedBox(height: 18),
                        _buildClimaHoje(),
                        const SizedBox(height: 14),
                        _buildAlertaDestaque(),
                        const SizedBox(height: 22),
                        _buildProximosAlertas(),
                      ],
                    ),
                  ),
                ),
              ),
              const _BarraNavegacao(),
            ],
          ),
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
    // direita. Aqui: o nome cadastrado, ou o nome de exemplo.
    final nomePropriedade = propriedade?.nome ?? 'Fazenda Boa Vista';

    return Row(
      children: [
        // Expanded faz o texto ocupar o espaço livre e empurra o sino e o
        // avatar para a direita.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Olá, João!',
                style: TextStyle(
                  color: _textoEscuro,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: _textoSuave),
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
          onPressed: () {
          },
          icon: const Icon(Icons.notifications_none, color: _textoEscuro),
        ),
        const CircleAvatar(
          radius: 18,
          backgroundColor: _verde,
          child: Icon(Icons.person, color: Colors.white, size: 22),
        ),
      ],
    );
  }

  Widget _buildClimaHoje() {
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
                // Text.rich permite misturar estilos no mesmo texto: aqui o
                // "24" é grande e o "°C" é menor, na mesma linha.
                Text.rich(
                  const TextSpan(
                    text: '24',
                    style: TextStyle(
                      color: _textoEscuro,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(
                        text: '°C',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Céu limpo',
                  style: TextStyle(color: _textoSuave, fontSize: 13),
                ),
              ],
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Máx.: 28°',
                style: TextStyle(color: _textoEscuro, fontSize: 13),
              ),
              SizedBox(height: 6),
              Text(
                'Mín.: 16°',
                style: TextStyle(color: _textoEscuro, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertaDestaque() {
    // InkWell dá o efeito de toque (ondulação) e permite clicar no cartão
    // inteiro. O Material por baixo é necessário para a ondulação aparecer
    // por cima da cor de fundo.
    return Material(
      color: const Color(0xFFFFF4E0),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF3D9A4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFE08A00), size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alerta de geada',
                      style: TextStyle(
                        color: Color(0xFF8A5300),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Risco alto para as próximas horas.',
                      style: TextStyle(color: Color(0xFF8A5300), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Color(0xFF8A5300)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProximosAlertas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Próximos alertas',
              style: TextStyle(
                color: _textoEscuro,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () {
              },
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
              // "collection for": monta um item para cada alerta da lista, sem
              // repetir código. O "if" dentro da lista coloca a linha
              // divisória entre os itens, menos depois do último.
              for (int i = 0; i < _proximos.length; i++) ...[
                _ItemAlerta(alerta: _proximos[i]),
                if (i < _proximos.length - 1)
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
// que cada item seja montado a partir de um _Alerta.
class _ItemAlerta extends StatelessWidget {
  final _Alerta alerta;

  const _ItemAlerta({required this.alerta});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: alerta.corFundo,
              child: Icon(alerta.icone, color: alerta.corIcone, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerta.titulo,
                    style: const TextStyle(
                      color: Color(0xFF1F2D27),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alerta.quando,
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

// Barra de navegação inferior (Início, Alertas, Histórico e Perfil). Por
// enquanto só "Início" está implementada, então o índice selecionado é fixo.
class _BarraNavegacao extends StatelessWidget {
  const _BarraNavegacao();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      // "fixed" mantém os quatro itens sempre com o texto visível.
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF1E7B58),
      unselectedItemColor: const Color(0xFF8A9690),
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (indice) {
      },
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
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Histórico',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
