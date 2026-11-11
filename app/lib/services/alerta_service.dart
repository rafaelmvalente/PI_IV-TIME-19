// Caique Vasconcelos Naimi - 25004208
// Data: 03/11/2026
// Descrição: Consulta alertas de exemplo, histórico e status em memória.

import '../data/alertas_exemplo.dart';
import '../models/alerta.dart';

class AlertaService {
  const AlertaService();

  // Dados de exemplo compartilhados pelo serviço durante a execução do app.
  static final List<Alerta> _alertas = [
    ...alertasDeExemplo(DateTime.now()),
    ...historicoDeExemplo(DateTime.now()),
  ];

  // Alertas de hoje em diante, do mais próximo para o mais distante.
  Future<List<Alerta>> listar(String propriedadeId, {TipoAlerta? tipo}) async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    return _alertas
        .where((a) => !a.previstoPara.isBefore(hoje))
        .where((a) => tipo == null || a.tipo == tipo)
        .toList()
      ..sort((a, b) => a.previstoPara.compareTo(b.previstoPara));
  }

  // Todos os alertas, do mais recente para o mais antigo.
  Future<List<Alerta>> listarHistorico(String propriedadeId) async {
    return [..._alertas]
      ..sort((a, b) => b.previstoPara.compareTo(a.previstoPara));
  }

  Future<Alerta> atualizarStatus(String alertaId, StatusAlerta status) async {
    final i = _alertas.indexWhere((a) => a.id == alertaId);
    if (i == -1) throw StateError('Alerta $alertaId não encontrado');
    return _alertas[i] = _alertas[i].copyWith(status: status);
  }
}
