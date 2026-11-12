// Caique Vasconcelos Naimi - 25004208
// Data: 03/11/2026
// Descrição: Serviço de consulta e atualização de alertas.
// Data: 11/11/2026
// Descrição: Integra alertas ao backend e usa o cache local quando não há rede.

import '../models/alerta.dart';
import 'api_client.dart';
import 'armazenamento_local_service.dart';

class AlertaService {
  AlertaService({ApiClient? api, ArmazenamentoLocalService? local})
    : _api = api ?? ApiClient(),
      _local = local ?? const ArmazenamentoLocalService();

  final ApiClient _api;
  final ArmazenamentoLocalService _local;

  Future<List<Alerta>> listar(String propriedadeId, {TipoAlerta? tipo}) async {
    if (propriedadeId.isEmpty) return [];
    try {
      final result =
          await _api.get(
                '/alerts',
                queryParameters: {
                  'propriedadeId': propriedadeId,
                  'periodo': 'proximos',
                  if (tipo != null) 'tipo': tipo.name,
                },
              )
              as List<dynamic>;
      final alerts = [
        for (final item in result)
          Alerta.fromJson(item as Map<String, dynamic>),
      ];
      await _salvarCache(propriedadeId, alerts);
      return alerts;
    } on ApiException catch (error) {
      if (error.statusCode != 0) rethrow;
      final cached = await _alertasEmCache(propriedadeId);
      if (cached.isEmpty) rethrow;
      return cached
          .where((alerta) => !alerta.previstoPara.isBefore(_inicioDeHoje()))
          .where((alerta) => tipo == null || alerta.tipo == tipo)
          .toList()
        ..sort((a, b) => a.previstoPara.compareTo(b.previstoPara));
    }
  }

  Future<List<Alerta>> listarHistorico(String propriedadeId) async {
    if (propriedadeId.isEmpty) return [];
    try {
      final result =
          await _api.get(
                '/alerts',
                queryParameters: {
                  'propriedadeId': propriedadeId,
                  'periodo': 'historico',
                },
              )
              as List<dynamic>;
      final alerts = [
        for (final item in result)
          Alerta.fromJson(item as Map<String, dynamic>),
      ];
      await _salvarCache(propriedadeId, alerts);
      return alerts;
    } on ApiException catch (error) {
      if (error.statusCode != 0) rethrow;
      final cached = await _alertasEmCache(propriedadeId);
      if (cached.isEmpty) rethrow;
      return cached
          .where((alerta) => alerta.previstoPara.isBefore(_inicioDeHoje()))
          .toList()
        ..sort((a, b) => b.previstoPara.compareTo(a.previstoPara));
    }
  }

  Future<Alerta> atualizarStatus(String alertaId, StatusAlerta status) async {
    try {
      final json =
          await _api.patch(
                '/alerts/$alertaId/status',
                body: {'status': status.name},
              )
              as Map<String, dynamic>;
      final updated = Alerta.fromJson(json);
      final cached = await _local.lerAlertas();
      final alerts = [
        for (final alert in cached)
          if (alert.id == updated.id) updated else alert,
      ];
      if (!alerts.any((alert) => alert.id == updated.id)) {
        alerts.add(updated);
      }
      await _local.salvarAlertas(alerts);
      return updated;
    } on ApiException catch (error) {
      if (error.statusCode == 0) {
        throw const ApiException(
          statusCode: 0,
          code: 'ALERT_STATUS_OFFLINE',
          message: 'Conecte-se à internet para atualizar o status do alerta.',
        );
      }
      rethrow;
    }
  }

  // Mesmo corte do backend: o alerta de hoje continua em "próximos" o dia todo.
  static DateTime _inicioDeHoje() {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  Future<List<Alerta>> _alertasEmCache(String propriedadeId) async {
    return (await _local.lerAlertas())
        .where((alerta) => alerta.propriedadeId == propriedadeId)
        .toList();
  }

  Future<void> _salvarCache(
    String propriedadeId,
    List<Alerta> atualizados,
  ) async {
    final previous = await _local.lerAlertas();
    final updatedIds = atualizados.map((alerta) => alerta.id).toSet();
    final retained = previous.where(
      (alerta) =>
          alerta.propriedadeId != propriedadeId ||
          !updatedIds.contains(alerta.id),
    );
    await _local.salvarAlertas([...retained, ...atualizados]);
  }
}
