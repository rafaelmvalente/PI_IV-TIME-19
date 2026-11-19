// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 13/10/2026
// Descrição: Modelo da propriedade rural cadastrada pelo produtor e os tipos
// de cultivo aceitos pelo app.
// Data: 11/11/2026
// Descrição: Inclui o identificador e a serialização do contrato da API.

import 'coordenada.dart';
import 'estagio_lavoura.dart';

// Culturas que o produtor pode escolher no cadastro. Cada valor tem:
// - o nome interno (milho, feijao...), que é o que vai para a API e o banco;
// - o rótulo, que é o texto com acento mostrado na tela.
// O backend usa o nome interno para buscar a tabela de risco da cultura.
enum TipoCultivo {
  milho('Milho'),
  feijao('Feijão'),
  soja('Soja'),
  cafe('Café'),
  hortalicas('Hortaliças'),
  frutas('Frutas'),
  outro('Outro');

  const TipoCultivo(this.rotulo);

  // Texto exibido no seletor de cultivo e no resumo da propriedade.
  final String rotulo;
}

// Propriedade rural do produtor. Imutável: para editar, o app cria um objeto
// novo com os dados alterados e envia para a API.
class Propriedade {
  const Propriedade({
    this.id,
    required this.nome,
    required this.cultivo,
    required this.localizacao,
    this.areaHectares,
    this.estagio,
  });

  // Identificador gerado pelo banco (MongoDB). Fica nulo enquanto a
  // propriedade ainda não foi salva no backend.
  final String? id;
  // Nome dado pelo produtor, ex.: "Sítio Boa Vista".
  final String nome;
  // Cultura plantada: define quais riscos (geada, seca, chuva) importam mais.
  final TipoCultivo cultivo;
  // Onde fica a propriedade: usada para buscar a previsão do tempo.
  final Coordenada localizacao;
  // Tamanho em hectares. Opcional, só informativo.
  final double? areaHectares;
  // Opcional: o produtor pode não saber ou não querer informar no cadastro.
  final EstagioLavoura? estagio;

  // Monta a Propriedade a partir do JSON que a API devolve
  // (GET /properties) ou do que ficou salvo no celular para o modo offline.
  factory Propriedade.fromJson(Map<String, dynamic> json) {
    return Propriedade(
      id: json['id'] as String?,
      nome: json['nome'] as String,
      // byName converte o texto "soja" de volta para TipoCultivo.soja.
      cultivo: TipoCultivo.values.byName(json['cultivo'] as String),
      // A API manda latitude e longitude soltas; aqui viram uma Coordenada.
      // "as num" + toDouble() porque o JSON pode trazer 47 (int) em vez de 47.0.
      localizacao: Coordenada(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      areaHectares: (json['areaHectares'] as num?)?.toDouble(),
      // Estágio é opcional: só converte quando veio preenchido.
      estagio: json['estagio'] == null
          ? null
          : EstagioLavoura.values.byName(json['estagio'] as String),
    );
  }

  // JSON para CRIAR a propriedade (POST /properties) e para salvar no
  // celular. Campos opcionais vazios ficam de fora do JSON ("if" dentro do
  // mapa), porque a API recusa valores nulos na criação.
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

  // JSON para EDITAR a propriedade (PATCH /properties/:id). Aqui os opcionais
  // vão mesmo nulos: um null diz à API "o produtor apagou este campo".
  // Se ficassem de fora, a API manteria o valor antigo.
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
