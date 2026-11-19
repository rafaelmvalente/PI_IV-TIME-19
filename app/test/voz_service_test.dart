// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 18/11/2026
// Descrição: Testa o texto lido em voz alta e o VozService (issue #17), com uma
// voz falsa no lugar do flutter_tts.

import 'package:app/models/alerta.dart';
import 'package:app/models/recomendacao.dart';
import 'package:app/services/voz_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _MotorFalso implements MotorDeVoz {
  final eventos = <String>[];
  bool falhaAoParar = false;

  @override
  Future<void> configurar(String idioma) async =>
      eventos.add('configurar:$idioma');

  @override
  Future<void> falar(String texto) async => eventos.add('falar:$texto');

  @override
  Future<void> parar() async {
    if (falhaAoParar) throw StateError('nada falando');
    eventos.add('parar');
  }
}

Alerta _alerta({
  DateTime? previstoPara,
  TipoAlerta tipo = TipoAlerta.geada,
  NivelRisco nivel = NivelRisco.alto,
  String acao = 'Proteja as plantas mais sensíveis',
  String detalhe = 'Cubra as plantas com lona ou plástico agrícola.',
}) {
  return Alerta(
    id: 'a1',
    propriedadeId: 'p1',
    tipo: tipo,
    nivel: nivel,
    previstoPara: previstoPara ?? DateTime.utc(2026, 11, 12, 12),
    descricao: 'A temperatura mínima prevista é de 1°C.',
    status: StatusAlerta.emAndamento,
    recomendacao: Recomendacao(acao: acao, detalhe: detalhe),
  );
}

void main() {
  final agora = DateTime(2026, 11, 11, 10);

  group('textoDoAlerta', () {
    test('lê o tipo, o nível, o dia e a recomendação', () {
      expect(
        textoDoAlerta(_alerta(), agora: agora),
        'Atenção: risco alto de geada, previsto para amanhã. '
        'Recomendação: Proteja as plantas mais sensíveis. '
        'Cubra as plantas com lona ou plástico agrícola.',
      );
    });

    test('diz hoje e ontem quando for o caso', () {
      final hoje = _alerta(previstoPara: DateTime.utc(2026, 11, 11, 12));
      final ontem = _alerta(previstoPara: DateTime.utc(2026, 11, 10, 12));

      expect(
        textoDoAlerta(hoje, agora: agora),
        contains('previsto para hoje.'),
      );
      expect(
        textoDoAlerta(ontem, agora: agora),
        contains('previsto para ontem.'),
      );
    });

    test('para datas mais distantes, diz o dia e o mês', () {
      final alerta = _alerta(
        previstoPara: DateTime.utc(2026, 11, 14, 12),
        tipo: TipoAlerta.seca,
        nivel: NivelRisco.medio,
      );

      expect(
        textoDoAlerta(alerta, agora: agora),
        startsWith(
          'Atenção: risco médio de seca prolongada, '
          'previsto para o dia 14 de novembro.',
        ),
      );
    });

    test('sem detalhe, lê só a ação', () {
      final texto = textoDoAlerta(_alerta(detalhe: ''), agora: agora);

      expect(
        texto,
        endsWith('Recomendação: Proteja as plantas mais sensíveis.'),
      );
    });

    test(
      'não repete o ponto final quando o texto já termina com pontuação',
      () {
        final texto = textoDoAlerta(
          _alerta(acao: 'Irrigue agora.', detalhe: 'De manhã cedo!'),
          agora: agora,
        );

        expect(texto, endsWith('Recomendação: Irrigue agora. De manhã cedo!'));
      },
    );
  });

  group('VozService', () {
    test('configura o português uma vez só e fala o alerta', () async {
      final motor = _MotorFalso();
      final voz = VozService(motor: motor, agora: () => agora);

      await voz.lerAlerta(_alerta());
      await voz.lerAlerta(_alerta());

      expect(motor.eventos.where((e) => e.startsWith('configurar')), [
        'configurar:pt-BR',
      ]);
      expect(motor.eventos.where((e) => e.startsWith('falar')).length, 2);
      expect(
        motor.eventos.first,
        'parar',
      ); // começa do zero se já estava falando
    });

    test('parar não dá erro quando o motor falha', () async {
      final motor = _MotorFalso()..falhaAoParar = true;
      final voz = VozService(motor: motor);

      await voz.parar();
    });
  });

  group('escolherVoz', () {
    test('prefere a voz neural do idioma', () {
      final voz = escolherVoz([
        {'name': 'Microsoft Maria - Portuguese (Brazil)', 'locale': 'pt-BR'},
        {'name': 'Microsoft Guy Online (Natural) - English', 'locale': 'en-US'},
        {
          'name': 'Microsoft Francisca Online (Natural) - Portuguese (Brazil)',
          'locale': 'pt-BR',
        },
        {'name': 'Google português do Brasil', 'locale': 'pt-BR'},
      ], 'pt-BR');

      expect(voz?['name'], contains('Francisca'));
    });

    test('aceita locale com sublinhado e cai na voz comum', () {
      final voz = escolherVoz([
        {'name': 'pt-br-x-afs-local', 'locale': 'pt_BR'},
      ], 'pt-BR');

      expect(voz?['name'], 'pt-br-x-afs-local');
    });

    test('sem voz do idioma devolve null', () {
      expect(
        escolherVoz([
          {'name': 'Samantha', 'locale': 'en-US'},
        ], 'pt-BR'),
        isNull,
      );
    });
  });
}
