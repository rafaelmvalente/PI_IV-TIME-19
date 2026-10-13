// Vinicius Santuci Virgolino - 25000294
// Data: 13/10/26
// Descrição: Modelo da propriedade rural cadastrada pelo produtor e os tipos
// de cultivo aceitos pelo app.

import 'coordenada.dart';

enum TipoCultivo {
  milho('Milho'),
  feijao('Feijão'),
  soja('Soja'),
  cafe('Café'),
  hortalicas('Hortaliças'),
  frutas('Frutas'),
  outro('Outro');

  const TipoCultivo(this.rotulo);

  final String rotulo;
}

class Propriedade {
  const Propriedade({
    required this.nome,
    required this.cultivo,
    required this.localizacao,
    this.areaHectares,
  });

  final String nome;
  final TipoCultivo cultivo;
  final Coordenada localizacao;
  final double? areaHectares;

  /// Formato usado para gravar no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'cultivo': cultivo.name,
      'latitude': localizacao.latitude,
      'longitude': localizacao.longitude,
      'areaHectares': areaHectares,
    };
  }
}