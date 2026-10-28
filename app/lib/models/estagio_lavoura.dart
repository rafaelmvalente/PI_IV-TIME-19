// Estrutura criada em 28/10/26 — implementação pendente (responsável: a definir)
// Descrição: Estágio da lavoura, usado para classificar o nível de risco do
// alerta (README: plantio, crescimento, floração, colheita).

// TODO(P026): adicionar o estágio ao modelo Propriedade e à tela de cadastro.
enum EstagioLavoura {
  plantio('Plantio'),
  crescimento('Crescimento'),
  floracao('Floração'),
  colheita('Colheita');

  const EstagioLavoura(this.rotulo);

  final String rotulo;
}
