// Vinicius Santuci Virgolino - 25000294
// Data: 28/10/2026
// Descrição: Cache local dos últimos alertas e do clima, para o app abrir
// sem internet (offline-first, estratégia WT do relatório), e detecção de
// quando o aparelho fica sem conexão para exibir o ModoOfflineScreen.

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alerta.dart';
import '../models/clima.dart';

class ArmazenamentoLocalService {
  const ArmazenamentoLocalService();

  static const _chaveAlertas = 'cache_alertas';
  static const _chaveClima = 'cache_clima';
  static const _chaveAtualizadoEm = 'cache_atualizado_em';

  // ---------- Cache ----------

  // Os dados são gravados como texto JSON no shared_preferences, que basta
  // para guardar só a última resposta de alertas e clima.
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

  Future<void> salvarClima(ClimaHoje clima) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveClima, jsonEncode(clima.toJson()));
    await _marcarAtualizacao(prefs);
  }

  // Devolve null se não houver cache ou se ele estiver corrompido.
  Future<ClimaHoje?> lerClima() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_chaveClima);
    if (json == null) return null;

    try {
      return ClimaHoje.fromJson(jsonDecode(json) as Map<String, dynamic>);
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
    await prefs.remove(_chaveClima);
    await prefs.remove(_chaveAtualizadoEm);
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
