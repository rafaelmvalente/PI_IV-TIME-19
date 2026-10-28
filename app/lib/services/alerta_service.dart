// Estrutura criada em 28/10/26 — implementação pendente (responsável: a definir)
// Descrição: Consulta alertas, histórico e atualiza o status da ação tomada
// pelo produtor.

import '../models/alerta.dart';

class AlertaService {
  const AlertaService();

  // TODO(P021): buscar alertas da propriedade, com filtro por tipo (endpoint a definir, P010).
  Future<List<Alerta>> listar(String propriedadeId, {TipoAlerta? tipo}) {
    throw UnimplementedError('P021: listar alertas não implementado');
  }

  // TODO(P021): buscar o histórico de alertas (endpoint a definir, P010).
  Future<List<Alerta>> listarHistorico(String propriedadeId) {
    throw UnimplementedError('P021: histórico não implementado');
  }

  // TODO(P021): enviar o novo status do alerta (endpoint a definir, P010).
  Future<Alerta> atualizarStatus(String alertaId, StatusAlerta status) {
    throw UnimplementedError('P021: atualizar status não implementado');
  }
}
