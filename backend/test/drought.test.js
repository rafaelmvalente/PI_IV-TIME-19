// Nome: Rodrigo Gabi - RA: 25001714
// Data: 11/11/2026
// Descrição: Testa a contagem de dias sem chuva e a seca prolongada (issue #11).

import test from 'node:test';
import assert from 'node:assert/strict';
import { buildRainTimeline, detectProlongedDrought, longestDryRun } from '../src/services/drought.js';
import { generateRiskAlerts } from '../src/services/risk.js';

const rule = { seca_dias_sem_chuva: { medio: 7, alto: 10 }, chuva_relevante_mm: 2 };

function history(start, rains) {
  return rains.map((chuvaMm, index) => ({
    data: new Date(Date.parse(`${start}T12:00:00.000Z`) + index * 86_400_000),
    chuvaMm,
  }));
}

function forecast(start, rains) {
  return rains.map((precipitation, index) => ({
    date: new Date(Date.parse(`${start}T00:00:00.000Z`) + index * 86_400_000).toISOString().slice(0, 10),
    minima: 15,
    maxima: 28,
    precipitation,
  }));
}

test('soma histórico e previsão na mesma sequência de dias secos', () => {
  // 5 dias secos no histórico (06 a 10) + 3 secos na previsão (11 a 13), depois chove.
  const result = detectProlongedDrought({
    history: history('2026-11-06', [0, 0, 1, 0, 0]),
    forecastDays: forecast('2026-11-11', [0, 1.5, 0, 20]),
    rule,
    today: '2026-11-11',
  });
  assert.equal(result.dias, 8);
  assert.equal(result.nivel, 'medio');
  assert.equal(result.inicio, '2026-11-06');
  // Data estável do alerta: o 7º dia seco.
  assert.equal(result.data, '2026-11-12');
});

test('chega a alto ao passar do limite alto', () => {
  const result = detectProlongedDrought({
    history: history('2026-11-01', Array(10).fill(0)),
    forecastDays: forecast('2026-11-11', [0, 0]),
    rule,
    today: '2026-11-11',
  });
  assert.equal(result.dias, 12);
  assert.equal(result.nivel, 'alto');
});

test('chuva relevante quebra a sequência', () => {
  const result = detectProlongedDrought({
    history: history('2026-11-01', [0, 0, 0, 0, 0, 0, 5, 0, 0, 0]),
    forecastDays: forecast('2026-11-11', [0, 0]),
    rule,
    today: '2026-11-11',
  });
  assert.equal(result, null);
});

test('seca que já terminou no passado não gera alerta', () => {
  const run = longestDryRun(
    buildRainTimeline(history('2026-10-25', [0, 0, 0, 0, 0, 0, 0, 0, 0, 10]), forecast('2026-11-04', [10])),
    '2026-11-04',
  );
  assert.equal(run, null);
});

test('dia sem leitura quebra a sequência em vez de contar como seco', () => {
  const gapped = [...history('2026-11-01', [0, 0, 0, 0]), ...history('2026-11-07', [0, 0, 0, 0])];
  const result = detectProlongedDrought({
    history: gapped,
    forecastDays: forecast('2026-11-11', [0]),
    rule,
    today: '2026-11-11',
  });
  assert.equal(result, null);
});

test('limite 0 desliga a regra (colheita)', () => {
  const result = detectProlongedDrought({
    history: history('2026-11-01', Array(10).fill(0)),
    forecastDays: forecast('2026-11-11', [0]),
    rule: { seca_dias_sem_chuva: { medio: 0, alto: 0 } },
    today: '2026-11-11',
  });
  assert.equal(result, null);
});

test('generateRiskAlerts gera um único alerta de seca com os dias na descrição', () => {
  const alerts = generateRiskAlerts(
    { _id: 'p1', cultivo: 'milho', estagio: 'floracao' },
    { daily: forecast('2026-11-11', [0, 0, 0]) },
    { ...rule, chuva_min_mm_semana: { medio: 20, alto: 10 } },
    { historico: history('2026-11-01', Array(10).fill(0)), hoje: '2026-11-11' },
  );
  const seca = alerts.filter((alert) => alert.tipo === 'seca');
  assert.equal(seca.length, 1);
  assert.equal(seca[0].nivel, 'alto');
  assert.equal(seca[0].previstoPara.toISOString(), '2026-11-07T12:00:00.000Z');
  assert.match(seca[0].descricao, /13 dias seguidos/);
  assert.match(seca[0].recomendacao.detalhe, /13 dias seguidos/);
});
