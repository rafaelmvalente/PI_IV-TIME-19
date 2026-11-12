// Caique Vasconcelos Naimi - 25004208
// Data: 11/11/2026
// Descrição: Valida as consultas e atualização de alertas via API simulada.

import 'dart:convert';

import 'package:app/models/alerta.dart';
import 'package:app/services/alerta_service.dart';
import 'package:app/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _alertJson({
  String id = 'alerta-1',
  String date = '2026-11-12T12:00:00.000Z',
  String status = 'emAndamento',
}) {
  return {
    'id': id,
    'propriedadeId': 'p1',
    'tipo': 'geada',
    'nivel': 'alto',
    'previstoPara': date,
    'descricao': 'Temperatura baixa prevista.',
    'status': status,
    'recomendacao': {
      'acao': 'Proteja as plantas',
      'detalhe': 'Cubra as plantas sensíveis.',
      'dicas': <String>[],
    },
  };
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('consulta próximos alertas com o id da propriedade', () async {
    late http.Request request;
    final service = AlertaService(
      api: ApiClient(
        baseUrl: 'http://localhost:3000/api/v1',
        client: MockClient((value) async {
          request = value;
          return http.Response(jsonEncode([_alertJson()]), 200);
        }),
      ),
    );

    final alerts = await service.listar('p1');

    expect(request.url.path, '/api/v1/alerts');
    expect(request.url.queryParameters, {
      'propriedadeId': 'p1',
      'periodo': 'proximos',
    });
    expect(alerts.single.id, 'alerta-1');
  });

  test('filtra os próximos alertas por tipo na consulta', () async {
    late http.Request request;
    final service = AlertaService(
      api: ApiClient(
        baseUrl: 'http://localhost:3000/api/v1',
        client: MockClient((value) async {
          request = value;
          return http.Response(jsonEncode([_alertJson()]), 200);
        }),
      ),
    );

    final alerts = await service.listar('p1', tipo: TipoAlerta.geada);

    expect(request.url.queryParameters['tipo'], 'geada');
    expect(alerts.single.tipo, TipoAlerta.geada);
  });

  test('offline, o alerta de hoje que já passou da hora continua nos próximos', () async {
    final agora = DateTime.now();
    final hojeCedo = DateTime(agora.year, agora.month, agora.day, 0, 1);
    var online = true;
    final service = AlertaService(
      api: ApiClient(
        baseUrl: 'http://localhost:3000/api/v1',
        client: MockClient((_) async {
          if (!online) throw http.ClientException('sem rede');
          return http.Response(
            jsonEncode([_alertJson(date: hojeCedo.toUtc().toIso8601String())]),
            200,
          );
        }),
      ),
    );

    await service.listar('p1');
    online = false;

    expect((await service.listar('p1')).single.id, 'alerta-1');
    expect(await service.listarHistorico('p1'), isEmpty);
  });

  test('consulta histórico e atualiza o status do alerta', () async {
    final requests = <http.Request>[];
    final service = AlertaService(
      api: ApiClient(
        baseUrl: 'http://localhost:3000/api/v1',
        client: MockClient((request) async {
          requests.add(request);
          final updated = _alertJson(status: 'resolvido');
          return http.Response(
            jsonEncode(request.method == 'PATCH' ? updated : [_alertJson()]),
            200,
          );
        }),
      ),
    );

    final history = await service.listarHistorico('p1');
    final updated = await service.atualizarStatus(
      'alerta-1',
      StatusAlerta.resolvido,
    );

    expect(requests.first.url.queryParameters['periodo'], 'historico');
    expect(history.single.id, 'alerta-1');
    expect(requests.last.method, 'PATCH');
    expect(jsonDecode(requests.last.body), {'status': 'resolvido'});
    expect(updated.status, StatusAlerta.resolvido);
  });
}
