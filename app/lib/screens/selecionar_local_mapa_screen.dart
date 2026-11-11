// Vinicius Santuci Virgolino - 25000294
// Data: 11/11/2026
// Descrição: Alternativa ao GPS no cadastro da propriedade. O produtor busca
// a cidade pelo nome, liga a vista de satélite para reconhecer a
// propriedade e toca no mapa onde ela fica. A tela devolve a Coordenada
// daquele ponto, o mesmo tipo que o GPS devolve.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/coordenada.dart';
import '../services/busca_local_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mapa_selecao_local.dart';

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

  final _mapController = MapController();
  final _buscaController = TextEditingController();
  late final _buscaLocal = widget.buscaLocalService ?? BuscaLocalService();

  // Onde o produtor tocou. null enquanto ainda não escolheu.
  late LatLng? _ponto = widget.localizacaoInicial == null
      ? null
      : LatLng(
          widget.localizacaoInicial!.latitude,
          widget.localizacaoInicial!.longitude,
        );
  bool _satelite = false;
  bool _buscando = false;
  String? _mensagemBusca;

  @override
  void dispose() {
    _mapController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  // A busca só acontece ao apertar "Buscar" (nunca a cada letra), como pede
  // a política de uso do Nominatim.
  Future<void> _buscar() async {
    FocusScope.of(context).unfocus();
    if (_buscaController.text.trim().isEmpty || _buscando) return;

    setState(() {
      _buscando = true;
      _mensagemBusca = null;
    });

    try {
      final local = await _buscaLocal.buscar(_buscaController.text);
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
      if (!mounted) return;
      setState(() => _mensagemBusca = erro.mensagem);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

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
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textoEscuro,
        elevation: 0,
        title: const Text(
          'Marcar no mapa',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _campoBusca(),
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
            Expanded(
              child: Stack(
                children: [
                  MapaSelecaoLocal(
                    controller: _mapController,
                    ponto: _ponto,
                    satelite: _satelite,
                    onTocar: (ponto) => setState(() => _ponto = ponto),
                  ),
                  Positioned(top: 12, right: 12, child: _botaoSatelite()),
                ],
              ),
            ),
            _botaoConfirmar(),
          ],
        ),
      ),
    );
  }

  Widget _campoBusca() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TextField(
        controller: _buscaController,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _buscar(),
        decoration: InputDecoration(
          hintText: 'Cidade ou bairro (ex.: Amparo, SP)',
          errorText: _mensagemBusca,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
  Widget _botaoSatelite() {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textoEscuro,
        elevation: 2,
      ),
      onPressed: () => setState(() => _satelite = !_satelite),
      icon: Icon(_satelite ? Icons.map_outlined : Icons.satellite_alt),
      label: Text(_satelite ? 'Mapa' : 'Satélite'),
    );
  }

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
