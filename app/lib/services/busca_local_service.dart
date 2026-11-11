// Vinicius Santuci Virgolino - 25000294
// Data: 11/11/2026
// Descrição: Busca um lugar pelo nome (cidade, bairro, distrito) e devolve a
// coordenada dele, para o mapa do cadastro ir direto até a região do
// produtor. Usa o Nominatim, a busca gratuita do OpenStreetMap.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/coordenada.dart';

class LocalEncontrado {
  const LocalEncontrado({required this.nome, required this.coordenada});

  // Nome completo do lugar (ex.: "Amparo, São Paulo, Região Sudeste, Brasil").
  final String nome;
  final Coordenada coordenada;
}

class BuscaLocalException implements Exception {
  const BuscaLocalException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

class BuscaLocalService {
  // O client pode ser trocado nos testes por um falso.
  BuscaLocalService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _tempoLimite = Duration(seconds: 10);

  // Política de uso do Nominatim: no máximo 1 busca por segundo, sem
  // autocompletar a cada letra, e o app precisa se identificar.
  // Devolve null se nenhum lugar for encontrado.
  Future<LocalEncontrado?> buscar(String texto) async {
    final termo = texto.trim();
    if (termo.isEmpty) return null;

    final url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': termo,
      'countrycodes': 'br', // só lugares do Brasil
      'format': 'jsonv2',
      'limit': '1',
      'accept-language': 'pt-BR',
    });

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
      throw const BuscaLocalException(
        'Não foi possível buscar. Verifique a internet e tente de novo.',
      );
    }

    if (resposta.statusCode != 200) {
      throw const BuscaLocalException(
        'A busca não está disponível agora. Tente de novo em instantes.',
      );
    }

    final lista = jsonDecode(resposta.body) as List;
    if (lista.isEmpty) return null;

    // O Nominatim manda latitude e longitude como texto.
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
