// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 11/11/2026
// Descrição: Alternativa ao GPS no cadastro da propriedade. O produtor busca
// a cidade pelo nome, liga a vista de satélite para reconhecer a
// propriedade e toca no mapa onde ela fica. A tela devolve a Coordenada
// daquele ponto, o mesmo tipo que o GPS devolve.

import 'package:flutter/material.dart';
// MapController: permite mover o mapa pelo código (ir até a cidade buscada).
import 'package:flutter_map/flutter_map.dart';
// LatLng: latitude + longitude no formato que o flutter_map entende.
import 'package:latlong2/latlong.dart';

import '../models/coordenada.dart';
import '../services/busca_local_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mapa_selecao_local.dart';

// StatefulWidget: a tela guarda estado que muda com o uso (ponto escolhido,
// satélite ligado, busca em andamento).
class SelecionarLocalMapaScreen extends StatefulWidget {
  const SelecionarLocalMapaScreen({
    super.key,
    this.localizacaoInicial,
    this.buscaLocalService,
  });

  // Se a propriedade já tem localização, o mapa abre nela com o pino.
  final Coordenada? localizacaoInicial;
  // Para testes: se vier nulo, usa o serviço de verdade.
  final BuscaLocalService? buscaLocalService;

  @override
  State<SelecionarLocalMapaScreen> createState() =>
      _SelecionarLocalMapaScreenState();
}

class _SelecionarLocalMapaScreenState extends State<SelecionarLocalMapaScreen> {
  // Zoom que mostra a cidade com as estradas rurais em volta.
  static const _zoomCidade = 13.0;

  // Controla a posição e o zoom do mapa.
  final _mapController = MapController();
  // Guarda o texto digitado no campo de busca.
  final _buscaController = TextEditingController();
  // "late": só é criado quando usado pela primeira vez (aí o widget já existe).
  late final _buscaLocal = widget.buscaLocalService ?? BuscaLocalService();

  // Onde o produtor tocou. null enquanto ainda não escolheu.
  // Começa com a localização que a propriedade já tinha, se houver
  // (convertida de Coordenada para LatLng).
  late LatLng? _ponto = widget.localizacaoInicial == null
      ? null
      : LatLng(
          widget.localizacaoInicial!.latitude,
          widget.localizacaoInicial!.longitude,
        );
  // Mapa de ruas (false) ou foto de satélite (true).
  bool _satelite = false;
  // true enquanto espera a resposta da busca: mostra a rodinha no campo.
  bool _buscando = false;
  // Mensagem embaixo do campo ("Nenhum lugar encontrado", erro de internet).
  String? _mensagemBusca;

  // Chamado quando a tela fecha: libera os controllers para não ficarem
  // ocupando memória.
  @override
  void dispose() {
    _mapController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  // A busca só acontece ao apertar "Buscar" (nunca a cada letra), como pede
  // a política de uso do Nominatim.
  Future<void> _buscar() async {
    // Fecha o teclado para o produtor ver o mapa.
    FocusScope.of(context).unfocus();
    // Ignora campo vazio e toques repetidos enquanto uma busca já está rodando.
    if (_buscaController.text.trim().isEmpty || _buscando) return;

    // Liga a rodinha e apaga a mensagem da busca anterior.
    setState(() {
      _buscando = true;
      _mensagemBusca = null;
    });

    try {
      final local = await _buscaLocal.buscar(_buscaController.text);
      // "mounted" = a tela ainda está aberta. Se o produtor voltou enquanto
      // a busca rodava, não dá para mexer numa tela que já fechou.
      if (!mounted) return;
      if (local == null) {
        setState(
          () => _mensagemBusca = 'Nenhum lugar encontrado com esse nome.',
        );
        return;
      }
      // Leva o mapa até a cidade; o produtor ainda precisa tocar na
      // propriedade.
      _mapController.move(
        LatLng(local.coordenada.latitude, local.coordenada.longitude),
        _zoomCidade,
      );
    } on BuscaLocalException catch (erro) {
      // Sem internet ou Nominatim fora do ar: mostra a mensagem no campo.
      if (!mounted) return;
      setState(() => _mensagemBusca = erro.mensagem);
    } finally {
      // "finally" roda com sucesso ou com erro: sempre desliga a rodinha.
      if (mounted) setState(() => _buscando = false);
    }
  }

  // Fecha a tela devolvendo o ponto escolhido para o cadastro da propriedade.
  // O "!" é seguro: o botão Confirmar só fica ativo quando _ponto não é nulo.
  // Converte de LatLng (do mapa) para Coordenada (modelo do app).
  void _confirmar() {
    final ponto = _ponto!;
    Navigator.of(
      context,
    ).pop(Coordenada(latitude: ponto.latitude, longitude: ponto.longitude));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      // Barra de cima com o título e a seta de voltar (o Flutter coloca a
      // seta sozinho porque a tela foi aberta com Navigator.push).
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        // Evita a barra mudar de cor quando o conteúdo rola por baixo.
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textoEscuro,
        elevation: 0,
        title: const Text(
          'Marcar no mapa',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      // SafeArea: não deixa o conteúdo ficar embaixo do entalhe da câmera
      // nem da barra de gestos do celular.
      body: SafeArea(
        child: Column(
          children: [
            // 1) Campo de busca da cidade.
            _campoBusca(),
            // 2) Instrução curta do que fazer.
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Busque sua cidade, aproxime o mapa e toque onde fica a '
                'propriedade.',
                style: TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            // 3) Mapa ocupando todo o espaço que sobra (Expanded).
            Expanded(
              // Stack: empilha o botão "Satélite" por cima do mapa.
              child: Stack(
                children: [
                  MapaSelecaoLocal(
                    controller: _mapController,
                    ponto: _ponto,
                    satelite: _satelite,
                    // Cada toque no mapa move o pino para o novo ponto.
                    onTocar: (ponto) => setState(() => _ponto = ponto),
                  ),
                  // Botão no canto superior direito do mapa.
                  Positioned(top: 12, right: 12, child: _botaoSatelite()),
                ],
              ),
            ),
            // 4) Botão de confirmar, fixo embaixo.
            _botaoConfirmar(),
          ],
        ),
      ),
    );
  }

  // Campo de texto da busca, com o botão de lupa (ou a rodinha) à direita.
  Widget _campoBusca() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TextField(
        controller: _buscaController,
        // O teclado mostra o botão "Pesquisar" no lugar do "Enter"...
        textInputAction: TextInputAction.search,
        // ...e apertar esse botão também faz a busca.
        onSubmitted: (_) => _buscar(),
        decoration: InputDecoration(
          hintText: 'Cidade ou bairro (ex.: Amparo, SP)',
          // Mostra a mensagem da busca em vermelho embaixo do campo.
          errorText: _mensagemBusca,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          // Durante a busca, a lupa vira uma rodinha de carregamento.
          suffixIcon: _buscando
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'Buscar',
                  icon: const Icon(Icons.search, color: AppColors.verde),
                  onPressed: _buscar,
                ),
        ),
      ),
    );
  }

  // Alterna entre o mapa comum e a foto de satélite.
  // O texto e o ícone mostram para qual modo o botão vai trocar.
  Widget _botaoSatelite() {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textoEscuro,
        // Sombra leve para o botão se destacar do mapa.
        elevation: 2,
      ),
      onPressed: () => setState(() => _satelite = !_satelite),
      icon: Icon(_satelite ? Icons.map_outlined : Icons.satellite_alt),
      label: Text(_satelite ? 'Mapa' : 'Satélite'),
    );
  }

  // Botão verde grande "Confirmar local", no rodapé da tela.
  Widget _botaoConfirmar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
          // Desabilitado até o produtor tocar no mapa.
          onPressed: _ponto == null ? null : _confirmar,
          child: const Text(
            'Confirmar local',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
