// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Consulta e persiste as propriedades do produtor autenticado.

import '../models/propriedade.dart';
import 'api_client.dart';

class PropriedadeService {
  const PropriedadeService();

  static final ApiClient _api = ApiClient();

  Future<Propriedade> salvar(Propriedade propriedade) async {
    final json =
        await _api.post('/properties', body: propriedade.toJson())
            as Map<String, dynamic>;
    return Propriedade.fromJson(json);
  }

  Future<List<Propriedade>> listarMinhas() async {
    final result = await _api.get('/properties') as List<dynamic>;
    return [
      for (final item in result)
        Propriedade.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<Propriedade> atualizar(String id, Propriedade propriedade) async {
    final json =
        await _api.patch('/properties/$id', body: propriedade.toPatchJson())
            as Map<String, dynamic>;
    return Propriedade.fromJson(json);
  }

  Future<void> remover(String id) => _api.delete('/properties/$id');
}
