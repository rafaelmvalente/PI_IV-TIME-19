// Vinicius Santuci Virgolino - 25000294
// Data: 28/10/2026
// Descrição: Cache local dos últimos alertas e do clima, para o app abrir
// sem internet (offline-first, estratégia WT do relatório), e detecção de
// quando o aparelho fica sem conexão para exibir o ModoOfflineScreen.
// Data: 11/11/2026
// Descrição: Separa o cache climático por propriedade para evitar dados trocados.

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alerta.dart';
import '../models/clima.dart';
import '../models/propriedade.dart';
import '../models/usuario.dart';
import 'auth_service.dart';

class ArmazenamentoLocalService {
  const ArmazenamentoLocalService();

  static const _chaveAlertas = 'cache_alertas';
  static const _prefixoChaveClima = 'cache_clima_';
  static const _prefixoChavePrevisao = 'cache_previsao_';
  static const _chaveAtualizadoEm = 'cache_atualizado_em';
  static const _chaveConta = 'cache_conta';

  // ---------- Conta ----------

  // Guarda quem entrou e a propriedade atual, para o app abrir sem internet
  // direto no dashboard. O token continua guardado pelo ApiClient.
  Future<void> salvarConta(Conta conta) async {
    final prefs = await SharedPreferences.getInstance();
    final propriedade = conta.propriedade;
    await prefs.setString(
      _chaveConta,
      jsonEncode({
        'login': conta.login,
        'usuario': conta.usuario.toJson(),
        // O toJson da propriedade não leva o id (é o corpo enviado à API),
        // mas o dashboard precisa dele para achar os alertas no cache.
        if (propriedade != null)
          'propriedade': {'id': propriedade.id, ...propriedade.toJson()},
      }),
    );
  }

  // Devolve null se não houver conta salva ou se ela estiver corrompida.
  Future<Conta?> lerConta() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_chaveConta);
    if (json == null) return null;

    try {
      final dados = jsonDecode(json) as Map<String, dynamic>;
      final propriedade = dados['propriedade'] as Map<String, dynamic>?;
      return Conta(
        login: dados['login'] as String,
        usuario: Usuario.fromJson(dados['usuario'] as Map<String, dynamic>),
        propriedade: propriedade == null
            ? null
            : Propriedade.fromJson(propriedade),
      );
    } catch (_) {
      return null;
    }
  }

  // Chamado ao sair da conta ou quando o login expira.
  Future<void> apagarConta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveConta);
  }

  // ---------- Cache ----------

  // Os dados são JSON no shared_preferences e separados pela propriedade.
  Future<void> salvarAlertas(List<Alerta> alertas) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode([for (final a in alertas) a.toJson()]);
    await prefs.setString(_chaveAlertas, json);
    await _marcarAtualizacao(prefs);
  }

  // Devolve lista vazia se não houver cache ou se ele estiver corrompido.
  Future<List<Alerta>> lerAlertas() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_chaveAlertas);
    if (json == null) return [];

    try {
      final lista = jsonDecode(json) as List;
      return [
        for (final item in lista) Alerta.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> salvarClima(
    ClimaHoje clima, {
    required String propriedadeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefixoChaveClima$propriedadeId',
      jsonEncode(clima.toJson()),
    );
    await _marcarAtualizacao(prefs);
  }

  // Devolve null se não houver cache ou se ele estiver corrompido.
  Future<ClimaHoje?> lerClima({required String propriedadeId}) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_prefixoChaveClima$propriedadeId');
    if (json == null) return null;

    try {
      return ClimaHoje.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> salvarPrevisao(
    PrevisaoClimatica previsao, {
    required String propriedadeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefixoChavePrevisao$propriedadeId',
      jsonEncode(previsao.toJson()),
    );
    await _marcarAtualizacao(prefs);
  }

  Future<PrevisaoClimatica?> lerPrevisao({
    required String propriedadeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_prefixoChavePrevisao$propriedadeId');
    if (json == null) return null;

    try {
      return PrevisaoClimatica.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  // Quando o cache foi salvo pela última vez, para mostrar ao produtor
  // "dados de hoje, 14:30" enquanto estiver offline.
  Future<DateTime?> ultimaAtualizacao() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chaveAtualizadoEm);
    return texto == null ? null : DateTime.tryParse(texto);
  }

  Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveAlertas);
    await prefs.remove(_chaveAtualizadoEm);
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefixoChaveClima) ||
          key.startsWith(_prefixoChavePrevisao)) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> _marcarAtualizacao(SharedPreferences prefs) {
    return prefs.setString(
      _chaveAtualizadoEm,
      DateTime.now().toIso8601String(),
    );
  }

  // ---------- Conexão ----------

  // O connectivity_plus informa se há Wi-Fi ou dados móveis ligados, não se
  // a internet realmente funciona. Para o aviso de modo offline, basta.
  Future<bool> estaOnline() async {
    final resultados = await Connectivity().checkConnectivity();
    return _temConexao(resultados);
  }

  // Emite true quando a conexão volta e false quando cai. "distinct" evita
  // avisar duas vezes seguidas o mesmo estado (ex.: troca de Wi-Fi para 4G).
  Stream<bool> mudancasDeConexao() {
    return Connectivity().onConnectivityChanged.map(_temConexao).distinct();
  }

  bool _temConexao(List<ConnectivityResult> resultados) {
    return resultados.any((r) => r != ConnectivityResult.none);
  }
}
