// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 11/11/2026
// Descrição: Mapa (via flutter_map) com um pino no ponto escolhido. Mostra
// o mapa do OpenStreetMap ou a vista de satélite da Esri, onde o produtor
// reconhece a casa, a estrada e a plantação. Avisa quem usa quando o
// produtor toca no mapa; quem guarda o ponto é a tela
// (SelecionarLocalMapaScreen).

import 'package:flutter/material.dart';
// flutter_map: desenha o mapa a partir de imagens (tiles) baixadas da internet.
import 'package:flutter_map/flutter_map.dart';
// latlong2: tipo LatLng (latitude + longitude) usado pelo flutter_map.
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

// Widget só de exibição (StatelessWidget): recebe o ponto e o tipo de mapa
// prontos da tela e devolve o toque pelo onTocar.
class MapaSelecaoLocal extends StatelessWidget {
  const MapaSelecaoLocal({
    super.key,
    required this.controller,
    required this.ponto,
    required this.satelite,
    required this.onTocar,
  });

  // Centro aproximado do Brasil, com zoom que mostra o país inteiro.
  static const _centroBrasil = LatLng(-15.8, -47.9);
  static const _zoomBrasil = 4.0;
  // Zoom de quando já existe um ponto: perto o bastante para ver a propriedade.
  static const _zoomPropriedade = 15.0;

  // Permite à tela mover o mapa (ex.: ir até a cidade buscada).
  final MapController controller;
  // Onde está o pino. null enquanto o produtor ainda não escolheu.
  final LatLng? ponto;
  // true = foto de satélite (Esri); false = mapa de ruas (OpenStreetMap).
  final bool satelite;
  // Chamado com a latitude/longitude do lugar onde o produtor tocou.
  final ValueChanged<LatLng> onTocar;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        // As posições iniciais só valem na primeira vez que o mapa abre;
        // depois quem move o mapa é o produtor ou o controller.
        // Se já existe um ponto, abre nele de perto; senão, no Brasil todo.
        initialCenter: ponto ?? _centroBrasil,
        initialZoom: ponto == null ? _zoomBrasil : _zoomPropriedade,
        // Limite de aproximação (nível de rua/casa).
        maxZoom: 19,
        // O flutter_map já converte o ponto tocado na tela em latitude e
        // longitude.
        onTap: (_, ponto) => onTocar(ponto),
      ),
      children: [
        // O mapa é um mosaico de imagens (tiles): {z} é o zoom e {x}/{y} a
        // posição de cada quadrado. Só os visíveis são baixados, por isso o
        // mapa precisa de internet.
        if (satelite) ...[
          // Imagens de satélite da Esri (gratuitas, com crédito na tela).
          // Atenção: aqui a ordem é {y}/{x}.
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/'
                'World_Imagery/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: _identificacaoApp,
            // Acima do zoom 18 nem toda região tem foto; amplia a do 18.
            maxNativeZoom: 18,
          ),
          // Nomes de cidades e divisas por cima da foto, para o produtor
          // não se perder.
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/'
                'Reference/World_Boundaries_and_Places/MapServer/tile/'
                '{z}/{y}/{x}',
            userAgentPackageName: _identificacaoApp,
            maxNativeZoom: 18,
          ),
        ] else
          // Mapa comum de ruas do OpenStreetMap (aqui a ordem é {x}/{y}).
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: _identificacaoApp,
          ),
        // Camada do pino vermelho, desenhada por cima do mapa. Só aparece
        // depois que existe um ponto escolhido.
        if (ponto != null)
          MarkerLayer(
            markers: [
              Marker(
                point: ponto!,
                width: 48,
                height: 48,
                // topCenter: a ponta do pino fica exatamente no ponto tocado.
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.location_pin,
                  size: 48,
                  color: AppColors.erro,
                ),
              ),
            ],
          ),
        // Crédito exigido pela licença de cada fonte de imagens.
        SimpleAttributionWidget(
          source: Text(
            satelite ? 'Imagens © Esri' : 'OpenStreetMap contributors',
          ),
        ),
      ],
    );
  }
}

// Identifica o app para os servidores de mapa, como pede a política de uso.
// Não pode ser "com.example.app": o OpenStreetMap bloqueia esse nome
// (devolve a imagem "Access blocked") e o mapa fica em branco.
const _identificacaoApp = 'br.com.climalerta';
