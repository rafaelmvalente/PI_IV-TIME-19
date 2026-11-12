// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 11/11/2026
// Descrição: Testes de cada regra de risco (geada, seca, chuva forte) e do
// generateRiskAlerts, que junta as três.

import assert from 'node:assert/strict';
import test from 'node:test';

import { RegraChuvaForte } from '../src/services/regras/RegraChuvaForte.js';
import { RegraGeada } from '../src/services/regras/RegraGeada.js';
import { RegraRisco } from '../src/services/regras/RegraRisco.js';
import { RegraSeca } from '../src/services/regras/RegraSeca.js';
import { generateRiskAlerts } from '../src/services/risk.js';

const propriedade = { _id: 'prop1' };

// Limites parecidos com os do milho em crescimento.
const regraCultura = {
  temp_min_c: { medio: 2, alto: 0 },
  chuva_min_mm_semana: { medio: 20, alto: 10 },
  chuva_max_mm_dia: { medio: 50, alto: 80 },
  chuva_max_mm_semana: { medio: 100, alto: 150 },
};

function dia(date, { minima = 15, precipitation = 10 } = {}) {
  return { date, maxima: 28, minima, precipitation };
}

test('RegraRisco não pode ser usada diretamente', () => {
  assert.throws(() => new RegraRisco('x'), /classe base/);
});

test('RegraGeada: médio, alto e sem risco', () => {
  const previsao = {
    daily: [
      dia('2026-11-12', { minima: 1.5 }),
      dia('2026-11-13', { minima: -1 }),
      dia('2026-11-14', { minima: 8 }),
    ],
  };

  const alertas = new RegraGeada().avaliar(propriedade, previsao, regraCultura);

  assert.equal(alertas.length, 2);
  assert.deepEqual(
    alertas.map((a) => [a.tipo, a.nivel]),
    [['geada', 'medio'], ['geada', 'alto']],
  );
  assert.equal(alertas[0].previstoPara.toISOString(), '2026-11-12T12:00:00.000Z');
  assert.match(alertas[1].descricao, /-1°C/);
  assert.equal(alertas[0].status, 'emAndamento');
  assert.equal(alertas[0].recomendacao.acao, 'Proteja as plantas mais sensíveis');
});

test('RegraGeada: sem limites na cultura não gera alerta', () => {
  const previsao = { daily: [dia('2026-11-12', { minima: -5 })] };
  assert.deepEqual(new RegraGeada().avaliar(propriedade, previsao, {}), []);
});

test('RegraSeca: nível médio com pouca chuva na semana', () => {
  const previsao = { daily: [dia('2026-11-12', { precipitation: 8 }), dia('2026-11-13', { precipitation: 7 })] };

  const alertas = new RegraSeca().avaliar(propriedade, previsao, regraCultura);

  assert.equal(alertas.length, 1);
  assert.equal(alertas[0].tipo, 'seca');
  assert.equal(alertas[0].nivel, 'medio');
  assert.equal(alertas[0].previstoPara.toISOString(), '2026-11-12T12:00:00.000Z');
  assert.match(alertas[0].descricao, /15\.0 mm/);
});

test('RegraSeca: nível alto quando quase não chove', () => {
  const previsao = { daily: [dia('2026-11-12', { precipitation: 2 })] };
  const [alerta] = new RegraSeca().avaliar(propriedade, previsao, regraCultura);
  assert.equal(alerta.nivel, 'alto');
});

test('RegraSeca: chuva suficiente não gera alerta', () => {
  const previsao = { daily: [dia('2026-11-12', { precipitation: 40 })] };
  assert.deepEqual(new RegraSeca().avaliar(propriedade, previsao, regraCultura), []);
});

test('RegraSeca: limites {0,0} (colheita) significam sem alerta', () => {
  const previsao = { daily: [dia('2026-11-12', { precipitation: 0 })] };
  const colheita = { chuva_min_mm_semana: { medio: 0, alto: 0 } };
  assert.deepEqual(new RegraSeca().avaliar(propriedade, previsao, colheita), []);
});

test('RegraSeca: sem dias de previsão não gera alerta', () => {
  assert.deepEqual(new RegraSeca().avaliar(propriedade, { daily: [] }, regraCultura), []);
});

test('RegraChuvaForte: chuva do dia, médio e alto', () => {
  const previsao = {
    daily: [
      dia('2026-11-12', { precipitation: 55 }),
      dia('2026-11-13', { precipitation: 90 }),
      dia('2026-11-14', { precipitation: 5 }),
    ],
  };
  // Sem limite semanal, para olhar só a regra do dia.
  const regra = { chuva_max_mm_dia: regraCultura.chuva_max_mm_dia };

  const alertas = new RegraChuvaForte().avaliar(propriedade, previsao, regra);

  assert.deepEqual(
    alertas.map((a) => [a.tipo, a.nivel]),
    [['chuvaForte', 'medio'], ['chuvaForte', 'alto']],
  );
});

test('RegraChuvaForte: chuva da semana vira alerta no primeiro dia', () => {
  const previsao = {
    daily: [dia('2026-11-12', { precipitation: 40 }), dia('2026-11-13', { precipitation: 40 }), dia('2026-11-14', { precipitation: 40 })],
  };

  const alertas = new RegraChuvaForte().avaliar(propriedade, previsao, regraCultura);

  assert.equal(alertas.length, 1);
  assert.equal(alertas[0].nivel, 'medio');
  assert.equal(alertas[0].previstoPara.toISOString(), '2026-11-12T12:00:00.000Z');
  assert.match(alertas[0].descricao, /120\.0 mm/);
});

test('RegraChuvaForte: no mesmo dia, fica um alerta só com o nível mais grave', () => {
  const previsao = {
    daily: [dia('2026-11-12', { precipitation: 85 }), dia('2026-11-13', { precipitation: 30 })],
  };
  // Dia 12: 85 mm (alto). Semana: 115 mm (médio). Deve ficar "alto".
  const alertas = new RegraChuvaForte().avaliar(propriedade, previsao, regraCultura);

  assert.equal(alertas.length, 1);
  assert.equal(alertas[0].nivel, 'alto');
});

test('generateRiskAlerts junta as regras: geada, chuva forte e seca, nessa ordem', () => {
  const previsao = {
    daily: [dia('2026-11-12', { minima: -1, precipitation: 90 })],
  };
  const regra = { ...regraCultura, chuva_min_mm_semana: { medio: 100, alto: 95 } };

  const alertas = generateRiskAlerts(propriedade, previsao, regra);

  assert.deepEqual(alertas.map((a) => a.tipo), ['geada', 'chuvaForte', 'seca']);
});
