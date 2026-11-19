// Rodrigo Gabi - 25001714
// Data: 28/10/2026
// Descrição: Estágio da lavoura, usado para classificar o nível de risco do
// alerta (README: plantio, crescimento, floração, colheita).

enum EstagioLavoura {
  plantio('Plantio'),
  crescimento('Crescimento'),
  floracao('Floração'),
  colheita('Colheita');

  const EstagioLavoura(this.rotulo);

  final String rotulo;
}
