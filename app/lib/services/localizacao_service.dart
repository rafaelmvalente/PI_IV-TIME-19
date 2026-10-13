// Vinicius Santuci Virgolino - 25000294
// Data: 13/10/26
// Descrição: Serviço que obtém a localização atual do aparelho pelo GPS,
// cuidando das permissões. Os erros são convertidos em mensagens simples
// para exibir ao produtor.

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/coordenada.dart';

class LocalizacaoException implements Exception {
  const LocalizacaoException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

class LocalizacaoService {
  const LocalizacaoService();

  static const Duration _tempoLimite = Duration(seconds: 20);

  Future<Coordenada> obterLocalizacaoAtual() async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      throw const LocalizacaoException(
        'Ative a localização (GPS) do aparelho e tente novamente.',
      );
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied) {
      throw const LocalizacaoException(
        'Permita o acesso à localização para cadastrar a propriedade.',
      );
    }
    if (permissao == LocationPermission.deniedForever) {
      throw const LocalizacaoException(
        'O acesso à localização está bloqueado. Libere nas configurações '
        'do aparelho.',
      );
    }

    try {
      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _tempoLimite,
        ),
      );
      return Coordenada(
        latitude: posicao.latitude,
        longitude: posicao.longitude,
      );
    } on TimeoutException {
      throw const LocalizacaoException(
        'Não foi possível obter a localização. Tente em um local aberto.',
      );
    }
  }
}