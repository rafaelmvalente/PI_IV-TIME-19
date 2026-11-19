// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 18/11/2026
// Descrição: Lê o alerta e a recomendação em voz alta para quem prefere áudio
// (issue #17, preferência "voz" do produtor). Quem de fato fala é o flutter_tts,
// mas ele fica atrás da interface MotorDeVoz, para os testes usarem uma voz
// falsa em vez do celular de verdade.

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/alerta.dart';

/// Quem de fato fala. O app usa o [MotorFlutterTts]; os testes usam um falso.
abstract class MotorDeVoz {
  Future<void> configurar(String idioma);

  /// Só termina quando a fala acaba.
  Future<void> falar(String texto);

  Future<void> parar();
}

/// O aparelho não tem voz no idioma pedido (ex.: sem voz em português instalada).
class VozIndisponivelException implements Exception {
  const VozIndisponivelException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

class MotorFlutterTts implements MotorDeVoz {
  MotorFlutterTts({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<void> configurar(String idioma) async {
    final disponivel = await _tts.isLanguageAvailable(idioma);
    if (disponivel != true && disponivel != 1) {
      throw const VozIndisponivelException(
        'A voz em português não está disponível neste aparelho.',
      );
    }
    await _tts.setLanguage(idioma);
    final voz = escolherVoz(await _vozesDoAparelho(), idioma);
    if (voz != null) await _tts.setVoice(voz);
    // Um pouco mais devagar que o normal, para ficar fácil de entender.
    // No navegador 1.0 é a velocidade normal; no celular, 0.5.
    await _tts.setSpeechRate(kIsWeb ? 0.9 : 0.45);
    // Faz o speak() só terminar quando a fala acabar: é assim que o botão
    // sabe a hora de voltar a mostrar "Ouvir alerta".
    await _tts.awaitSpeakCompletion(true);
  }

  // Sem a lista de vozes (ex.: o navegador ainda não carregou), fica a voz
  // padrão do idioma.
  Future<List<Map<String, String>>> _vozesDoAparelho() async {
    try {
      final vozes = await _tts.getVoices as List? ?? const [];
      return [
        for (final voz in vozes.whereType<Map>())
          {for (final e in voz.entries) '${e.key}': '${e.value}'},
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> falar(String texto) async {
    await _tts.speak(texto);
  }

  @override
  Future<void> parar() async {
    await _tts.stop();
  }
}

/// Escolhe a voz do idioma que soa mais natural. As vozes neurais ("Natural" e
/// "Online" no Edge, "Google" no Chrome, "network" no Android) são bem menos
/// robóticas que a voz padrão do sistema. Devolve null se não houver voz do idioma.
Map<String, String>? escolherVoz(
  List<Map<String, String>> vozes,
  String idioma,
) {
  int nota(Map<String, String> voz) {
    final nome = (voz['name'] ?? '').toLowerCase();
    if (nome.contains('natural')) return 4;
    if (nome.contains('online')) return 3;
    if (nome.contains('google')) return 2;
    if (nome.contains('network')) return 1;
    return 0;
  }

  final doIdioma = vozes
      .where(
        (voz) =>
            (voz['locale'] ?? '').replaceAll('_', '-').toLowerCase() ==
            idioma.toLowerCase(),
      )
      .toList();
  if (doIdioma.isEmpty) return null;
  return doIdioma.reduce(
    (melhor, voz) => nota(voz) > nota(melhor) ? voz : melhor,
  );
}

class VozService {
  VozService({MotorDeVoz? motor, DateTime Function()? agora})
    : _motor = motor ?? MotorFlutterTts(),
      _agora = agora ?? DateTime.now;

  static const idioma = 'pt-BR';

  final MotorDeVoz _motor;
  final DateTime Function() _agora;
  bool _configurado = false;

  /// Lê o tipo, o nível e o dia do alerta, e depois a recomendação.
  Future<void> lerAlerta(Alerta alerta) {
    return falar(textoDoAlerta(alerta, agora: _agora()));
  }

  Future<void> falar(String texto) async {
    await parar(); // se já estava falando, começa do zero
    if (!_configurado) {
      await _motor.configurar(idioma);
      _configurado = true;
    }
    await _motor.falar(texto);
  }

  /// Nunca dá erro: parar sem estar falando não é problema.
  Future<void> parar() async {
    try {
      await _motor.parar();
    } catch (_) {}
  }
}

const _meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// Monta o texto que será lido, por exemplo:
/// "Atenção: risco alto de geada, previsto para amanhã. Recomendação: Proteja
/// as plantas mais sensíveis. Cubra as plantas com lona ou plástico agrícola."
String textoDoAlerta(Alerta alerta, {DateTime? agora}) {
  final dia = _descreverDia(alerta.previstoPara, agora ?? DateTime.now());
  final recomendacao = alerta.recomendacao;

  final frases = <String>[
    'Atenção: risco ${alerta.nivel.rotulo.toLowerCase()} de '
        '${alerta.tipo.rotulo.toLowerCase()}, previsto para $dia.',
    'Recomendação: ${_comPonto(recomendacao.acao)}',
    if (recomendacao.detalhe.trim().isNotEmpty) _comPonto(recomendacao.detalhe),
  ];
  return frases.join(' ');
}

String _descreverDia(DateTime previstoPara, DateTime agora) {
  final data = previstoPara.toLocal();
  // Compara só o dia (sem a hora). Em UTC, para o horário de verão não
  // atrapalhar a conta dos dias.
  final diaDoAlerta = DateTime.utc(data.year, data.month, data.day);
  final hoje = DateTime.utc(agora.year, agora.month, agora.day);
  return switch (diaDoAlerta.difference(hoje).inDays) {
    0 => 'hoje',
    1 => 'amanhã',
    -1 => 'ontem',
    _ => 'o dia ${data.day} de ${_meses[data.month - 1]}',
  };
}

String _comPonto(String texto) {
  final limpo = texto.trim();
  if (limpo.isEmpty) return limpo;
  final ultimo = limpo[limpo.length - 1];
  return (ultimo == '.' || ultimo == '!' || ultimo == '?') ? limpo : '$limpo.';
}
