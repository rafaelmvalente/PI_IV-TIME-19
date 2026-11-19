// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 28/10/2026
// Descrição: Cache local dos últimos alertas e do clima, para o app abrir
// sem internet (offline-first, estratégia WT do relatório), e detecção de
// quando o aparelho fica sem conexão para exibir o ModoOfflineScreen.
// Data: 11/11/2026
// Descrição: Separa o cache climático por propriedade para evitar dados trocados.

// jsonEncode/jsonDecode: convertem objetos em texto JSON e de volta.
import 'dart:convert';

// connectivity_plus: diz se o aparelho está com Wi-Fi ou dados móveis.
import 'package:connectivity_plus/connectivity_plus.dart';
// shared_preferences: guarda pares chave/valor no próprio celular
// (no navegador, no localStorage). Os dados continuam lá ao fechar o app.
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alerta.dart';
import '../models/clima.dart';
import '../models/propriedade.dart';
import '../models/usuario.dart';
import 'auth_service.dart';

// Tudo o que o app guarda no celular para funcionar sem internet.
// Como o shared_preferences só guarda textos e números, cada objeto vira um
// texto JSON antes de ser salvo e volta a ser objeto ao ser lido.
class ArmazenamentoLocalService {
  const ArmazenamentoLocalService();

  // Nomes (chaves) com que cada dado é guardado no celular.
  static const _chaveAlertas = 'cache_alertas';
  // Clima e previsão usam um prefixo + o id da propriedade
  // (ex.: "cache_clima_65f1..."), para cada propriedade ter o seu.
  static const _prefixoChaveClima = 'cache_clima_';
  static const _prefixoChavePrevisao = 'cache_previsao_';
  static const _chaveAtualizadoEm = 'cache_atualizado_em';
  static const _chaveConta = 'cache_conta';

  // ---------- Conta ----------

  // Guarda quem entrou e a propriedade atual, para o app abrir sem internet
  // direto no dashboard. O token continua guardado pelo ApiClient.
  Future<void> salvarConta(Conta conta) async {
    // getInstance abre o armazenamento do celular (é sempre a mesma instância).
    final prefs = await SharedPreferences.getInstance();
    final propriedade = conta.propriedade;
    await prefs.setString(
      _chaveConta,
      jsonEncode({
        'login': conta.login,
        'usuario': conta.usuario.toJson(),
        // O toJson da propriedade não leva o id (é o corpo enviado à API),
        // mas o dashboard precisa dele para achar os alertas no cache.
        // O "..." espalha os campos do toJson dentro deste mapa.
        if (propriedade != null)
          'propriedade': {'id': propriedade.id, ...propriedade.toJson()},
      }),
    );
  }

  // Devolve null se não houver conta salva ou se ela estiver corrompida.
  Future<Conta?> lerConta() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_chaveConta);
    // Ninguém entrou ainda neste celular (ou já saiu da conta).
    if (json == null) return null;

    try {
      final dados = jsonDecode(json) as Map<String, dynamic>;
      final propriedade = dados['propriedade'] as Map<String, dynamic>?;
      return Conta(
        login: dados['login'] as String,
        usuario: Usuario.fromJson(dados['usuario'] as Map<String, dynamic>),
        // Conta sem propriedade cadastrada ainda: fica nula.
        propriedade: propriedade == null
            ? null
            : Propriedade.fromJson(propriedade),
      );
    } catch (_) {
      // JSON estragado (ex.: formato de uma versão antiga do app): em vez de
      // travar, age como se não houvesse conta e o produtor entra de novo.
      return null;
    }
  }

  // Chamado ao sair da conta ou quando o login expira.
  Future<void> apagarConta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveConta);
  }

  // ---------- Cache ----------

  // Os dados são JSON no shared_preferences. Os alertas ficam numa chave só
  // (cada alerta já traz o id da sua propriedade); clima e previsão ficam
  // separados por propriedade.
  // Cada vez que salva, substitui a lista antiga pela nova.
  Future<void> salvarAlertas(List<Alerta> alertas) async {
    final prefs = await SharedPreferences.getInstance();
    // Converte cada alerta em mapa e a lista inteira em um único texto JSON.
    final json = jsonEncode([for (final a in alertas) a.toJson()]);
    await prefs.setString(_chaveAlertas, json);
    // Anota a hora, para a faixa "dados de hoje, 14:30".
    await _marcarAtualizacao(prefs);
  }

  // Devolve lista vazia se não houver cache ou se ele estiver corrompido.
  Future<List<Alerta>> lerAlertas() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_chaveAlertas);
    if (json == null) return [];

    try {
      final lista = jsonDecode(json) as List;
      // Transforma cada item da lista de volta em um objeto Alerta.
      return [
        for (final item in lista) Alerta.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  // Clima de agora (temperatura, chuva, vento) da propriedade informada.
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

  // Previsão dos próximos dias da propriedade informada.
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

  // Devolve null se não houver cache ou se ele estiver corrompido.
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
  // tryParse devolve null (em vez de dar erro) se o texto estiver estragado.
  Future<DateTime?> ultimaAtualizacao() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chaveAtualizadoEm);
    return texto == null ? null : DateTime.tryParse(texto);
  }

  // Grava a data e a hora atuais em texto (formato ISO, ex.:
  // "2026-11-18T14:30:00.000"), que o tryParse acima sabe ler de volta.
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

  // O aparelho pode ter várias conexões ao mesmo tempo (Wi-Fi e 4G).
  // Basta uma delas ser diferente de "none" para contar como online.
  bool _temConexao(List<ConnectivityResult> resultados) {
    return resultados.any((r) => r != ConnectivityResult.none);
  }
}
