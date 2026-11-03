// Caique Vasconcelos Naimi - 25004208
// Data: 03/11/2026
// Descrição: Consulta alertas, histórico e atualiza o status da ação tomada
// pelo produtor. Enquanto o backend não existe (P010), usa os alertas de
// exemplo guardados na memória do app.

import '../data/alertas_exemplo.dart';
import '../models/alerta.dart';

class AlertaService {
  const AlertaService();

  // shortcut: alertas de exemplo em memória, iguais para qualquer propriedade
  // e perdidos ao fechar o app; trocar pelas chamadas ao backend (P021/P010).
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
