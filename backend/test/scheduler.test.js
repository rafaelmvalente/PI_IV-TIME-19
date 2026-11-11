// Nome: Rodrigo Gabi - RA: 25001714
// Data: 11/11/2026
// Descrição: Testa o agendamento da coleta e análise automática (issue #8).

import test from 'node:test';
import assert from 'node:assert/strict';

process.env.JWT_SECRET ??= 'segredo-de-teste-com-pelo-menos-32-caracteres';
const { runCollectionCycle, startCollectionScheduler } = await import('../src/services/scheduler.js');

const silent = { error() {}, warn() {}, log() {} };
const nextTick = () => new Promise((resolve) => setImmediate(resolve));

function fakeDb(properties) {
  return {
    collection: () => ({
      find: () => ({
        async *[Symbol.asyncIterator]() {
          yield* properties;
        },
      }),
    }),
  };
}

test('analisa todas as propriedades e continua quando uma falha', async () => {
  const seen = [];
  const summary = await runCollectionCycle(fakeDb([{ _id: 1 }, { _id: 2 }, { _id: 3 }]), {
    refresh: async (_db, property) => {
      seen.push(property._id);
      if (property._id === 2) throw new Error('Open-Meteo fora do ar');
    },
    logger: silent,
  });
  assert.deepEqual(seen, [1, 2, 3]);
  assert.equal(summary.total, 3);
  assert.equal(summary.sucesso, 2);
  assert.equal(summary.falhas, 1);
});

test('intervalo 0 desliga o agendamento', async () => {
  let runs = 0;
  const scheduler = startCollectionScheduler({}, {
    intervalMinutes: 0,
    runCycle: async () => {
      runs += 1;
    },
    logger: silent,
  });
  await scheduler.stop();
  assert.equal(runs, 0);
});

test('pula o ciclo quando o anterior ainda está rodando', async () => {
  let runs = 0;
  let finish;
  const scheduler = startCollectionScheduler({}, {
    intervalMinutes: 60,
    initialDelayMs: 60_000,
    runCycle: () => {
      runs += 1;
      return new Promise((resolve) => {
        finish = resolve;
      });
    },
    logger: silent,
  });

  scheduler.tick();
  await nextTick();
  scheduler.tick();
  assert.equal(runs, 1);

  finish();
  await scheduler.stop();
  scheduler.tick();
  await nextTick();
  assert.equal(runs, 2);
  finish();
});
