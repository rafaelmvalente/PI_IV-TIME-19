// Nome: Rafael Mendes Valente - RA: 25002875
// Dia: 11/11/2026
// Descrição: Classifica riscos de geada, seca e chuva forte conforme as regras agrícolas.

const recommendations = {
  geada: {
    acao: 'Proteja as plantas mais sensíveis',
    detalhe: 'Cubra as plantas com lona ou plástico agrícola antes da queda de temperatura.',
    dicas: ['Evite irrigar no fim do dia.', 'Retire a cobertura quando a temperatura subir.'],
  },
  seca: {
    acao: 'Economize e planeje a irrigação',
    detalhe: 'Priorize as áreas mais sensíveis e acompanhe a umidade do solo.',
    dicas: ['Irrigue nos horários mais frescos.', 'Verifique vazamentos no sistema.'],
  },
  chuvaForte: {
    acao: 'Prepare a drenagem da lavoura',
    detalhe: 'Desobstrua valetas e canais para facilitar o escoamento da água.',
    dicas: ['Evite aplicar insumos antes da chuva.', 'Observe as áreas mais baixas.'],
  },
};

function riskLevel(observed, thresholds, below = false) {
  if (!thresholds) return null;
  // Limites de geada e seca indicam risco quando a medição fica abaixo do valor.
  const high = below ? observed <= thresholds.alto : observed >= thresholds.alto;
  if (high) return 'alto';
  const medium = below ? observed <= thresholds.medio : observed >= thresholds.medio;
  return medium ? 'medio' : null;
}

function alertFor(propriedade, tipo, nivel, date, descricao) {
  return {
    propriedadeId: propriedade._id,
    tipo,
    nivel,
    previstoPara: new Date(`${date}T12:00:00.000Z`),
    descricao,
    status: 'emAndamento',
    recomendacao: recommendations[tipo],
    atualizadoEm: new Date(),
  };
}

export function generateRiskAlerts(propriedade, forecast, rule) {
  const alerts = [];
  const { temp_min_c, chuva_min_mm_semana, chuva_max_mm_dia, chuva_max_mm_semana } = rule;
  const rainAlerts = new Map();

  for (const day of forecast.daily) {
    const frostLevel = riskLevel(day.minima, temp_min_c, true);
    if (frostLevel) {
      alerts.push(
        alertFor(
          propriedade,
          'geada',
          frostLevel,
          day.date,
          `A temperatura mínima prevista é de ${day.minima}°C.`,
        ),
      );
    }

    const dailyRainLevel = riskLevel(day.precipitation, chuva_max_mm_dia);
    if (dailyRainLevel) {
      rainAlerts.set(
        day.date,
        alertFor(
          propriedade,
          'chuvaForte',
          dailyRainLevel,
          day.date,
          `A previsão indica ${day.precipitation} mm de chuva no dia.`,
        ),
      );
    }
  }

  const weeklyRain = forecast.daily.reduce((sum, day) => sum + (day.precipitation ?? 0), 0);
  const weeklyRainLevel = riskLevel(weeklyRain, chuva_max_mm_semana);
  if (weeklyRainLevel && forecast.daily.length) {
    const date = forecast.daily[0].date;
    const existingAlert = rainAlerts.get(date);
    const level =
      existingAlert?.nivel === 'alto' || weeklyRainLevel === 'alto' ? 'alto' : 'medio';
    rainAlerts.set(
      date,
      alertFor(
        propriedade,
        'chuvaForte',
        level,
        date,
        `A previsão indica ${weeklyRain.toFixed(1)} mm de chuva nos próximos dias.`,
      ),
    );
  }
  alerts.push(...rainAlerts.values());

  const droughtLevel = riskLevel(weeklyRain, chuva_min_mm_semana, true);
  if (droughtLevel && forecast.daily.length) {
    alerts.push(
      alertFor(
        propriedade,
        'seca',
        droughtLevel,
        forecast.daily[0].date,
        `A previsão indica apenas ${weeklyRain.toFixed(1)} mm de chuva nos próximos dias.`,
      ),
    );
  }

  return alerts;
}
