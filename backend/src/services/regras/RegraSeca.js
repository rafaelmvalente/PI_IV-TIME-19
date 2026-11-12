// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 11/11/2026
// Descrição: Regra de seca. Soma a chuva da semana e avisa quando ela fica
// igual ou abaixo dos limites da cultura (chuva_min_mm_semana).
// Limites { medio: 0, alto: 0 } significam "esta fase não tem alerta de seca"
// (é o caso de todos os estágios de colheita).

import { RegraRisco } from './RegraRisco.js';

export class RegraSeca extends RegraRisco {
  constructor() {
    super('seca');
  }

  avaliar(propriedade, forecast, regraCultura) {
    const limites = regraCultura.chuva_min_mm_semana;
    if (!forecast.daily.length || this.semLimites(limites)) return [];

    const chuvaDaSemana = this.somaDaChuva(forecast);
    const nivel = this.nivelDeRisco(chuvaDaSemana, limites, true);
    if (!nivel) return [];

    return [
      this.criarAlerta(
        propriedade,
        nivel,
        forecast.daily[0].date,
        `A previsão indica apenas ${chuvaDaSemana.toFixed(1)} mm de chuva nos próximos dias.`,
      ),
    ];
  }

  semLimites(limites) {
    return !limites || (limites.medio === 0 && limites.alto === 0);
  }
}
