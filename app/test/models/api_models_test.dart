// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Valida a conversão dos modelos usados no contrato das APIs.

import 'package:app/models/clima.dart';
import 'package:app/models/coordenada.dart';
import 'package:app/models/preferencias_alerta.dart';
import 'package:app/models/propriedade.dart';
import 'package:app/models/usuario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte usuário e preferências enviados pela API', () {
    final user = Usuario.fromJson({
      'id': 'user-1',
      'nome': 'Ana',
      'email': 'ana@example.com',
      'telefone': null,
      'preferencias': {'texto': true, 'voz': true, 'sms': false},
    });

    expect(user.id, 'user-1');
    expect(user.preferencias.voz, isTrue);
    expect(user.toJson()['preferencias'], {
      'texto': true,
      'voz': true,
      'sms': false,
    });
    expect(
      PreferenciasAlerta.fromJson(user.preferencias.toJson()).algumAtivo,
      isTrue,
    );
  });

  test('converte propriedade e permite limpar campos opcionais em PATCH', () {
    final property = Propriedade.fromJson({
      'id': 'property-1',
      'nome': 'Sítio Verde',
      'cultivo': 'soja',
      'latitude': -23.5,
      'longitude': -46.6,
      'areaHectares': 5,
      'estagio': 'plantio',
    });

    final withoutOptionalFields = Propriedade(
      id: property.id,
      nome: property.nome,
      cultivo: property.cultivo,
      localizacao: const Coordenada(latitude: -23.5, longitude: -46.6),
    );

    expect(property.id, 'property-1');
    expect(property.toJson()['cultivo'], 'soja');
    expect(withoutOptionalFields.toJson().containsKey('areaHectares'), isFalse);
    expect(withoutOptionalFields.toPatchJson()['areaHectares'], isNull);
    expect(withoutOptionalFields.toPatchJson()['estagio'], isNull);
  });

  test('converte previsão atual e diária retornadas pelo backend', () {
    final forecast = PrevisaoClimatica.fromJson({
      'current': {'temperatura': 21.5, 'descricao': 'Parcialmente nublado'},
      'daily': [
        {
          'date': '2026-11-11',
          'maxima': 27,
          'minima': 15,
          'precipitation': 2.5,
        },
        {'date': '2026-11-12', 'maxima': 28, 'minima': 16, 'precipitation': 0},
      ],
    });

    expect(forecast.atual.temperatura, 21.5);
    expect(forecast.atual.maxima, 27);
    expect(forecast.dias, hasLength(2));
    expect(forecast.dias.last.precipitacao, 0);
  });
}
