// Nome: Rodrigo Gabi - RA: 25001714
// Data: 11/11/2026
// Descrição: Testa as recomendações práticas por tipo, nível e estágio (issue #12).

import test from 'node:test';
import assert from 'node:assert/strict';
import { recommendationFor } from '../src/services/recommendations.js';

test('tem ação, detalhe e dicas para todo tipo e nível', () => {
  for (const tipo of ['geada', 'seca', 'chuvaForte']) {
    for (const nivel of ['medio', 'alto']) {
      const rec = recommendationFor(tipo, nivel);
      assert.ok(rec.acao.length > 0, `${tipo}/${nivel} sem ação`);
      assert.ok(rec.detalhe.length > 0, `${tipo}/${nivel} sem detalhe`);
      assert.ok(rec.dicas.length >= 2, `${tipo}/${nivel} com poucas dicas`);
    }
  }
});

test('nível alto muda a ação sugerida', () => {
  assert.notEqual(recommendationFor('geada', 'medio').acao, recommendationFor('geada', 'alto').acao);
});

test('acrescenta a dica do estágio da lavoura', () => {
  const semEstagio = recommendationFor('seca', 'alto');
  const floracao = recommendationFor('seca', 'alto', { estagio: 'floracao' });
  assert.equal(floracao.dicas.length, semEstagio.dicas.length + 1);
  assert.match(floracao.dicas.at(-1), /floração/);
});

test('não altera as dicas base entre chamadas', () => {
  recommendationFor('geada', 'alto', { estagio: 'plantio' });
  assert.equal(recommendationFor('geada', 'alto').dicas.length, 3);
});

test('tipo desconhecido gera erro', () => {
  assert.throws(() => recommendationFor('neve', 'alto'));
});
