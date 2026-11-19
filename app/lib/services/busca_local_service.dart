// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 11/11/2026
// Descrição: Busca um lugar pelo nome (cidade, bairro, distrito) e devolve a
// coordenada dele, para o mapa do cadastro ir direto até a região do
// produtor. Usa o Nominatim, a busca gratuita do OpenStreetMap.

// jsonDecode: transforma o texto JSON da resposta em listas e mapas do Dart.
import 'dart:convert';

// kIsWeb: diz se o app está rodando no navegador.
import 'package:flutter/foundation.dart';
// Pacote http: faz a requisição GET para o Nominatim.
import 'package:http/http.dart' as http;

import '../models/coordenada.dart';

// Resultado da busca: o nome do lugar e onde ele fica.
class LocalEncontrado {
  const LocalEncontrado({required this.nome, required this.coordenada});

  // Nome completo do lugar (ex.: "Amparo, São Paulo, Região Sudeste, Brasil").
  final String nome;
  // Ponto para onde o mapa vai se mover.
  final Coordenada coordenada;
}

// Erro da busca com a mensagem pronta para a tela (mesma ideia da
// LocalizacaoException do GPS).
class BuscaLocalException implements Exception {
  const BuscaLocalException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

class BuscaLocalService {
  // O client pode ser trocado nos testes por um falso.
  // Sem client informado (no app de verdade), cria um http.Client normal.
  BuscaLocalService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Se o Nominatim não responder em 10 s, desistimos e mostramos o erro.
  static const _tempoLimite = Duration(seconds: 10);

  // Política de uso do Nominatim: no máximo 1 busca por segundo, sem
  // autocompletar a cada letra, e o app precisa se identificar.
  // Por isso a busca só acontece quando o produtor confirma o texto.
  // Devolve null se nenhum lugar for encontrado.
  Future<LocalEncontrado?> buscar(String texto) async {
    // Tira espaços do começo e do fim. Texto vazio nem chega a ir à internet.
    final termo = texto.trim();
    if (termo.isEmpty) return null;

    // Monta a URL com os parâmetros da busca. O Uri.https já cuida de
    // codificar acentos e espaços (ex.: "São Paulo" vira "S%C3%A3o+Paulo").
    final url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': termo, // o que o produtor digitou
      'countrycodes': 'br', // só lugares do Brasil
      'format': 'jsonv2', // resposta em JSON
      'limit': '1', // só o resultado mais relevante
      'accept-language': 'pt-BR', // nomes em português
    });

    // "final" sem valor: a variável recebe o valor dentro do try, uma vez só.
    final http.Response resposta;
    try {
      resposta = await _client
          .get(
            url,
            // Na web o navegador não deixa trocar o User-Agent; lá o
            // Nominatim identifica o app pelo endereço da página (Referer).
            headers: kIsWeb
                ? null
                : const {'User-Agent': 'ClimAlerta/1.0 (projeto academico)'},
          )
          .timeout(_tempoLimite);
    } on Exception {
      // Sem internet ou demorou demais (timeout): mesma mensagem para os dois.
      throw const BuscaLocalException(
        'Não foi possível buscar. Verifique a internet e tente de novo.',
      );
    }

    // Qualquer resposta diferente de 200 (OK) é problema do lado do
    // Nominatim, por exemplo, excesso de buscas (429).
    if (resposta.statusCode != 200) {
      throw const BuscaLocalException(
        'A busca não está disponível agora. Tente de novo em instantes.',
      );
    }

    // A resposta é uma lista de lugares. Lista vazia = nada encontrado.
    final lista = jsonDecode(resposta.body) as List;
    if (lista.isEmpty) return null;

    // O Nominatim manda latitude e longitude como texto.
    // Por isso o double.parse, que converte "-22.70" em -22.70.
    final lugar = lista.first as Map<String, dynamic>;
    return LocalEncontrado(
      nome: lugar['display_name'] as String,
      coordenada: Coordenada(
        latitude: double.parse(lugar['lat'] as String),
        longitude: double.parse(lugar['lon'] as String),
      ),
    );
  }
}
