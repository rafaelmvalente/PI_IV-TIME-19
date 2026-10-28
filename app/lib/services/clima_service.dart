// Estrutura criada em 28/10/26 — implementação pendente (responsável: a definir)
// Descrição: Busca o clima do dia da propriedade. A definir com a arquitetura
// do backend se os dados vêm do backend ou direto da API (INMET/OpenWeather).

import '../models/clima.dart';

class ClimaService {
  const ClimaService();

  // TODO(P021): buscar o clima do dia (endpoint a definir, P010).
  Future<ClimaHoje> climaDeHoje(String propriedadeId) {
    throw UnimplementedError('P021: clima do dia não implementado');
  }
}
