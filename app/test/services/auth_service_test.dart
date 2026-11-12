// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Valida o cadastro e login com a API HTTP simulada.

import 'dart:convert';

import 'package:app/services/api_client.dart';
import 'package:app/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'envia cadastro e autentica guardando o token para chamadas privadas',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUrl: 'http://localhost:3000/api/v1',
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/auth/login')) {
            return http.Response(
              jsonEncode({
                'usuario': {
                  'id': 'usuario-1',
                  'nome': 'Ana Produtora',
                  'email': 'ana@example.com',
                  'telefone': null,
                  'preferencias': {'texto': true, 'voz': false, 'sms': false},
                },
                'token': 'token-de-teste',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.endsWith('/properties')) {
            return http.Response(
              jsonEncode([
                {
                  'id': 'propriedade-1',
                  'nome': 'Sítio Verde',
                  'cultivo': 'soja',
                  'latitude': -23.5,
                  'longitude': -46.6,
                  'areaHectares': 12,
                  'estagio': 'plantio',
                },
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 201);
        }),
      );
      final auth = AuthService(api: client);

      await auth.criarConta(
        nome: 'Ana Produtora',
        login: 'ana@example.com',
        senha: 'senha-segura-123',
      );
      final conta = await auth.entrar('ana@example.com', 'senha-segura-123');

      expect(jsonDecode(requests.first.body), {
        'nome': 'Ana Produtora',
        'senha': 'senha-segura-123',
        'email': 'ana@example.com',
      });
      expect(conta?.usuario.nome, 'Ana Produtora');
      expect(conta?.propriedade?.id, 'propriedade-1');
      expect(requests.last.headers['authorization'], 'Bearer token-de-teste');
    },
  );
}
