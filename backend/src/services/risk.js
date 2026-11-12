// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 11/11/2026
// Descrição: Gera os alertas de risco de uma propriedade. Só organiza o
// trabalho: cada regra (geada, chuva forte, seca) mora na sua própria classe,
// em services/regras/. Para criar um novo tipo de alerta, basta criar uma
// regra nova e colocá-la na lista abaixo.
// opcoes.historico (leituras_clima) e opcoes.hoje: usados na seca prolongada (#11).

import { RegraChuvaForte } from './regras/RegraChuvaForte.js';
import { RegraGeada } from './regras/RegraGeada.js';
import { RegraSeca } from './regras/RegraSeca.js';

const regras = [new RegraGeada(), new RegraChuvaForte(), new RegraSeca()];

export function generateRiskAlerts(propriedade, forecast, rule, opcoes = {}) {
  return regras.flatMap((regra) => regra.avaliar(propriedade, forecast, rule, opcoes));
}
