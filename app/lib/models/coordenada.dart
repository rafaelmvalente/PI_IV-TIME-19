// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 13/10/2026
// Descrição: Par de latitude e longitude que identifica onde fica a
// propriedade. É o dado usado para consultar a previsão do tempo.

// Classe imutável (campos final e construtor const): uma coordenada não muda
// depois de criada; para trocar o local, cria-se outra.
class Coordenada {
  const Coordenada({required this.latitude, required this.longitude});

  // Graus decimais. Latitude: norte/sul (negativa no Brasil, abaixo do
  // Equador). Longitude: leste/oeste (negativa no Brasil, a oeste de Greenwich).
  final double latitude;
  final double longitude;

  // Texto para mostrar na tela, ex.: "-22.90561, -47.06212".
  // Cinco casas decimais dão precisão de cerca de 1 metro, suficiente para
  // identificar a propriedade sem encher a tela de números.
  String get descricao =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}
