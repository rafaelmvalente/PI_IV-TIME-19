// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 11/11/2026
// Descrição: Regra de seca. Avisa a seca prolongada (dias seguidos sem chuva)
// ou, se não houver, soma a chuva da semana e avisa quando ela fica
// igual ou abaixo dos limites da cultura (chuva_min_mm_semana).
// Limites { medio: 0, alto: 0 } significam "esta fase não tem alerta de seca"
// (é o caso de todos os estágios de colheita).

import { detectProlongedDrought } from '../drought.js';
import { RegraRisco } from './RegraRisco.js';

export class RegraSeca extends RegraRisco {
  constructor() {
    super('seca');
  }

  avaliar(propriedade, forecast, regraCultura, opcoes = {}) {
    if (!forecast.daily.length) return [];
    const limites = regraCultura.chuva_min_mm_semana;
    const chuvaDaSemana = this.somaDaChuva(forecast);
    const nivel = this.semLimites(limites) ? null : this.nivelDeRisco(chuvaDaSemana, limites, true);

    // Seca prolongada (#11): dias seguidos sem chuva, juntando leituras_clima e a previsão.
    const prolongada = detectProlongedDrought({
      history: opcoes.historico,
      forecastDays: forecast.daily,
      rule: regraCultura,
      today: opcoes.hoje,
    });
    if (prolongada) {
      // Um único alerta de seca, com o nível mais grave entre as duas medidas.
      return [
        this.criarAlerta(
          propriedade,
          prolongada.nivel === 'alto' || nivel === 'alto' ? 'alto' : 'medio',
          prolongada.data,
          `São ${prolongada.dias} dias seguidos sem chuva relevante, contando a previsão.`,
          { diasSemChuva: prolongada.dias },
        ),
      ];
    }

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
