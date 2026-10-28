// Estrutura criada em 28/10/26 — implementação pendente (responsável: a definir)
// Descrição: Salva e consulta a propriedade do produtor no backend
// (endpoints a definir, P010).

import '../models/propriedade.dart';

class PropriedadeService {
  const PropriedadeService();

  // TODO(P021): salvar no backend (chamado ao salvar o cadastro, P026).
  Future<Propriedade> salvar(Propriedade propriedade) {
    throw UnimplementedError('P021: salvar propriedade não implementado');
  }

  // TODO(P021): buscar as propriedades do usuário logado.
  Future<List<Propriedade>> listarMinhas() {
    throw UnimplementedError('P021: listar propriedades não implementado');
  }

  // TODO(P033): enviar a edição feita na tela de Perfil.
  Future<Propriedade> atualizar(String id, Propriedade propriedade) {
    throw UnimplementedError('P033: editar propriedade não implementado');
  }
}
