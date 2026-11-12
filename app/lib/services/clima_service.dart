// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Busca o clima e a previsão da propriedade pela API autenticada.

import '../models/clima.dart';
import 'api_client.dart';
import 'armazenamento_local_service.dart';

class ClimaService {
  const ClimaService();

  static final ApiClient _api = ApiClient();
  static const ArmazenamentoLocalService _local = ArmazenamentoLocalService();

  Future<ClimaHoje> climaDeHoje(String propriedadeId) async {
    try {
      final json =
          await _api.get('/properties/$propriedadeId/weather/today')
              as Map<String, dynamic>;
      final clima = ClimaHoje.fromJson(json);
      await _local.salvarClima(clima, propriedadeId: propriedadeId);
      return clima;
    } on ApiException catch (error) {
      if (error.statusCode != 0) rethrow;
      final cached = await _local.lerClima(propriedadeId: propriedadeId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<PrevisaoClimatica> previsao(String propriedadeId) async {
    try {
      final json =
          await _api.get('/properties/$propriedadeId/weather/forecast')
              as Map<String, dynamic>;
      final forecast = PrevisaoClimatica.fromJson(json);
      await _local.salvarClima(forecast.atual, propriedadeId: propriedadeId);
      await _local.salvarPrevisao(forecast, propriedadeId: propriedadeId);
      return forecast;
    } on ApiException catch (error) {
      if (error.statusCode != 0) rethrow;
      final cached = await _local.lerPrevisao(propriedadeId: propriedadeId);
      if (cached != null) return cached;
      rethrow;
    }
  }
}
