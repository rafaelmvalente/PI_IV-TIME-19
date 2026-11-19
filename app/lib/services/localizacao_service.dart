// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 13/10/2026
// Descrição: Serviço que obtém a localização atual do aparelho pelo GPS,
// cuidando das permissões. Os erros são convertidos em mensagens simples
// para exibir ao produtor.

// TimeoutException: erro lançado quando o GPS demora mais que o tempo limite.
import 'dart:async';

// Pacote geolocator: conversa com o GPS do Android, do iOS e do navegador.
import 'package:geolocator/geolocator.dart';

import '../models/coordenada.dart';

// Erro próprio da localização. Carrega só a mensagem pronta para mostrar na
// tela, assim quem chama não precisa saber o que deu errado no GPS.
class LocalizacaoException implements Exception {
  const LocalizacaoException(this.mensagem);

  // Texto que aparece para o produtor (ex.: "Ative a localização...").
  final String mensagem;

  // Ao imprimir o erro (print ou log), mostra a mensagem em vez de
  // "Instance of LocalizacaoException".
  @override
  String toString() => mensagem;
}

// Serviço sem estado: só tem um método, por isso pode ser const.
class LocalizacaoService {
  const LocalizacaoService();

  // Tempo máximo esperando o GPS responder. Em lugar fechado ou com sinal
  // fraco ele pode nunca achar a posição; depois de 20 s desistimos.
  static const Duration _tempoLimite = Duration(seconds: 20);

  // Devolve a latitude e a longitude de onde o aparelho está agora.
  // Antes de ler o GPS, confere três coisas, nesta ordem:
  // 1) se o GPS do aparelho está ligado;
  // 2) se o app tem permissão (e pede, se ainda não pediu);
  // 3) se a permissão não foi bloqueada para sempre.
  // Se algo falhar, lança LocalizacaoException com a mensagem para a tela.
  Future<Coordenada> obterLocalizacaoAtual() async {
    // 1) GPS desligado nas configurações do celular: não adianta pedir
    // permissão, o produtor precisa ligar a localização primeiro.
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      throw const LocalizacaoException(
        'Ative a localização (GPS) do aparelho e tente novamente.',
      );
    }

    // 2) Verifica a permissão atual. Se ainda não foi dada, o sistema mostra
    // a janela "Permitir que o ClimAlerta acesse sua localização?".
    // É "var" porque o valor pode mudar depois do pedido.
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    // O produtor recusou na janela: avisamos para que ele possa tentar de novo.
    if (permissao == LocationPermission.denied) {
      throw const LocalizacaoException(
        'Permita o acesso à localização para cadastrar a propriedade.',
      );
    }
    // 3) "Não perguntar novamente": o app não pode mais abrir a janela,
    // só o próprio produtor libera nas configurações do aparelho.
    if (permissao == LocationPermission.deniedForever) {
      throw const LocalizacaoException(
        'O acesso à localização está bloqueado. Libere nas configurações '
        'do aparelho.',
      );
    }

    try {
      // Lê a posição atual com precisão alta (usa o GPS, e não só a rede),
      // porque a previsão do tempo depende do local exato da propriedade.
      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _tempoLimite,
        ),
      );
      // Converte a posição do geolocator para o nosso modelo Coordenada,
      // que é o que o resto do app usa.
      return Coordenada(
        latitude: posicao.latitude,
        longitude: posicao.longitude,
      );
    } on TimeoutException {
      // Passaram os 20 s sem resposta do GPS (comum dentro de casa).
      throw const LocalizacaoException(
        'Não foi possível obter a localização. Tente em um local aberto.',
      );
    }
  }
}
