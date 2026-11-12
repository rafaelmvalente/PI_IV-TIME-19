// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 11/11/2026
// Descrição: Regra de chuva forte. Olha a chuva de cada dia (chuva_max_mm_dia)
// e a chuva somada da semana (chuva_max_mm_semana). Quando os dois avisos caem
// no mesmo dia, fica um alerta só, com o nível mais grave.

import { RegraRisco } from './RegraRisco.js';

export class RegraChuvaForte extends RegraRisco {
  constructor() {
    super('chuvaForte');
  }

  avaliar(propriedade, forecast, regraCultura) {
    // Guarda um alerta por data, para não repetir o mesmo dia.
    const alertasPorData = new Map();

    for (const dia of forecast.daily) {
      const nivel = this.nivelDeRisco(dia.precipitation, regraCultura.chuva_max_mm_dia);
      if (nivel) {
        alertasPorData.set(
          dia.date,
          this.criarAlerta(
            propriedade,
            nivel,
            dia.date,
            `A previsão indica ${dia.precipitation} mm de chuva no dia.`,
          ),
        );
      }
    }

    if (forecast.daily.length) {
      const chuvaDaSemana = this.somaDaChuva(forecast);
      const nivelDaSemana = this.nivelDeRisco(chuvaDaSemana, regraCultura.chuva_max_mm_semana);
      if (nivelDaSemana) {
        // O aviso da semana vale para o primeiro dia da previsão.
        const data = forecast.daily[0].date;
        const doDia = alertasPorData.get(data);
        const nivel = doDia?.nivel === 'alto' || nivelDaSemana === 'alto' ? 'alto' : 'medio';
        alertasPorData.set(
          data,
          this.criarAlerta(
            propriedade,
            nivel,
            data,
            `A previsão indica ${chuvaDaSemana.toFixed(1)} mm de chuva nos próximos dias.`,
          ),
        );
      }
    }

    return [...alertasPorData.values()];
  }
}
