// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Testa a classificação de riscos climáticos nas previsões agrícolas.

import test from 'node:test';
import assert from 'node:assert/strict';
import { generateRiskAlerts } from '../src/services/risk.js';

const propriedade = {
  _id: 'property-id',
  cultivo: 'milho',
  estagio: 'crescimento',
};

const regra = {
  temp_min_c: { medio: 2, alto: 0 },
  chuva_min_mm_semana: { medio: 20, alto: 10 },
  chuva_max_mm_dia: { medio: 50, alto: 80 },
  chuva_max_mm_semana: { medio: 100, alto: 150 },
};

test('gera alertas de geada e chuva forte usando os limites da cultura', () => {
  const forecast = {
    daily: [
      { date: '2026-11-12', minima: 0, maxima: 20, precipitation: 85 },
      { date: '2026-11-13', minima: 8, maxima: 20, precipitation: 0 },
    ],
  };

  const alerts = generateRiskAlerts(propriedade, forecast, regra);
  assert.deepEqual(alerts.map((alert) => [alert.tipo, alert.nivel]), [
    ['geada', 'alto'],
    ['chuvaForte', 'alto'],
  ]);
  assert.equal(alerts[0].status, 'emAndamento');
  assert.equal(alerts[0].recomendacao.acao, 'Proteja as plantas mais sensíveis');
});

test('classifica seca pelo total de chuva previsto para a semana', () => {
  const forecast = {
    daily: [
      { date: '2026-11-12', minima: 12, maxima: 22, precipitation: 1 },
      { date: '2026-11-13', minima: 10, maxima: 21, precipitation: 1 },
    ],
  };

  const alerts = generateRiskAlerts(propriedade, forecast, regra);
  assert.deepEqual(alerts.map((alert) => [alert.tipo, alert.nivel]), [['seca', 'alto']]);
});

test('não gera alerta quando a previsão está dentro dos limites', () => {
  const forecast = {
    daily: [
      { date: '2026-11-12', minima: 12, maxima: 22, precipitation: 15 },
      { date: '2026-11-13', minima: 10, maxima: 21, precipitation: 8 },
    ],
  };

  assert.deepEqual(generateRiskAlerts(propriedade, forecast, regra), []);
});
