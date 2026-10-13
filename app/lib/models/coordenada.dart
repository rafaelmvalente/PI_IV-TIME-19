// Vinicius Santuci Virgolino - 25000294
// Data: 13/10/26
// Descrição: Par de latitude e longitude que identifica onde fica a
// propriedade. É o dado usado para consultar a previsão do tempo.

class Coordenada {
  const Coordenada({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  String get descricao =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}