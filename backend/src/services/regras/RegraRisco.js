// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 11/11/2026
// Descrição: Classe base das regras de risco climático. Cada tipo de alerta
// (geada, seca, chuva forte) é uma classe filha que implementa avaliar().
// Aqui ficam as partes que todas as regras usam: comparar com os limites,
// somar a chuva da semana e montar o alerta.

import { recomendacoes } from './recomendacoes.js';

export class RegraRisco {
  constructor(tipo) {
    if (new.target === RegraRisco) {
      throw new Error('RegraRisco é uma classe base: use RegraGeada, RegraSeca ou RegraChuvaForte.');
    }
    this.tipo = tipo;
  }

  // Recebe a propriedade, a previsão do tempo e os limites da cultura
  // (documento de risco_cultura) e devolve a lista de alertas desta regra.
  avaliar(propriedade, forecast, regraCultura) {
    throw new Error(`A regra "${this.tipo}" precisa implementar avaliar().`);
  }

  // Compara o valor previsto com os limites { medio, alto }.
  // Com abaixo = true, o risco aparece quando o valor fica ABAIXO do limite
  // (geada e seca). Com abaixo = false, quando fica ACIMA (chuva forte).
  nivelDeRisco(valor, limites, abaixo = false) {
    if (!limites) return null;
    const alto = abaixo ? valor <= limites.alto : valor >= limites.alto;
    if (alto) return 'alto';
    const medio = abaixo ? valor <= limites.medio : valor >= limites.medio;
    return medio ? 'medio' : null;
  }

  // Chuva somada dos dias da previsão (a "semana").
  somaDaChuva(forecast) {
    return forecast.daily.reduce((soma, dia) => soma + (dia.precipitation ?? 0), 0);
  }

  criarAlerta(propriedade, nivel, data, descricao) {
    return {
      propriedadeId: propriedade._id,
      tipo: this.tipo,
      nivel,
      previstoPara: new Date(`${data}T12:00:00.000Z`),
      descricao,
      status: 'emAndamento',
      recomendacao: recomendacoes[this.tipo],
      atualizadoEm: new Date(),
    };
  }
}
