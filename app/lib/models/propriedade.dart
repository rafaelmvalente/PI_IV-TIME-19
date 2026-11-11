// Vinicius Santuci Virgolino - 25000294
// Data: 13/10/26
// Descrição: Modelo da propriedade rural cadastrada pelo produtor e os tipos
// de cultivo aceitos pelo app.
// Data: 11/11/2026
// Descrição: Inclui o identificador e a serialização do contrato da API.

import 'coordenada.dart';
import 'estagio_lavoura.dart';

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
    this.id,
    required this.nome,
    required this.cultivo,
    required this.localizacao,
    this.areaHectares,
    this.estagio,
  });

  final String? id;
  final String nome;
  final TipoCultivo cultivo;
  final Coordenada localizacao;
  final double? areaHectares;
  // Opcional: o produtor pode não saber ou não querer informar no cadastro.
  final EstagioLavoura? estagio;

  /// Formato usado para gravar no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'cultivo': cultivo.name,
      'latitude': localizacao.latitude,
      'longitude': localizacao.longitude,
      'areaHectares': areaHectares,
      'estagio': estagio?.name,
    };
  }

  factory Propriedade.fromJson(Map<String, dynamic> json) {
    return Propriedade(
      id: json['id'] as String?,
      nome: json['nome'] as String,
      cultivo: TipoCultivo.values.byName(json['cultivo'] as String),
      localizacao: Coordenada(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      areaHectares: (json['areaHectares'] as num?)?.toDouble(),
      estagio: json['estagio'] == null
          ? null
          : EstagioLavoura.values.byName(json['estagio'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'cultivo': cultivo.name,
      'latitude': localizacao.latitude,
      'longitude': localizacao.longitude,
      if (areaHectares != null) 'areaHectares': areaHectares,
      if (estagio != null) 'estagio': estagio!.name,
    };
  }

  Map<String, dynamic> toPatchJson() {
    return {
      'nome': nome,
      'cultivo': cultivo.name,
      'latitude': localizacao.latitude,
      'longitude': localizacao.longitude,
      'areaHectares': areaHectares,
      'estagio': estagio?.name,
    };
  }
}
