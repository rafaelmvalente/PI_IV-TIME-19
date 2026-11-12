// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 11/11/2026
// Descrição: Regra de geada. Gera um alerta para cada dia em que a temperatura
// mínima prevista fica igual ou abaixo dos limites da cultura (temp_min_c).

import { RegraRisco } from './RegraRisco.js';

export class RegraGeada extends RegraRisco {
  constructor() {
    super('geada');
  }

  avaliar(propriedade, forecast, regraCultura) {
    const alertas = [];

    for (const dia of forecast.daily) {
      const nivel = this.nivelDeRisco(dia.minima, regraCultura.temp_min_c, true);
      if (nivel) {
        alertas.push(
          this.criarAlerta(
            propriedade,
            nivel,
            dia.date,
            `A temperatura mínima prevista é de ${dia.minima}°C.`,
          ),
        );
      }
    }

    return alertas;
  }
}
