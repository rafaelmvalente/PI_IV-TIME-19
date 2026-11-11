// Nome: Rodrigo Gabi - RA: 25001714
// Data: 11/11/2026
// Descrição: Calcula os dias seguidos sem chuva relevante e classifica a seca prolongada (issue #11).

const DAY_MS = 24 * 60 * 60 * 1000;
export const DEFAULT_RELEVANT_RAIN_MM = 2;

function toDay(value) {
  // Aceita "2026-11-12" (previsão) ou Date (leituras_clima) e devolve "2026-11-12".
  return value instanceof Date ? value.toISOString().slice(0, 10) : String(value).slice(0, 10);
}

function nextDay(day) {
  return new Date(Date.parse(`${day}T00:00:00.000Z`) + DAY_MS).toISOString().slice(0, 10);
}

function addDays(day, amount) {
  return new Date(Date.parse(`${day}T00:00:00.000Z`) + amount * DAY_MS).toISOString().slice(0, 10);
}

// Junta o histórico observado (leituras_clima) com a previsão. Para o mesmo dia,
// a previsão vence, porque o histórico só guarda dias que já terminaram.
export function buildRainTimeline(history = [], forecastDays = []) {
  const byDay = new Map();
  for (const reading of history) {
    if (Number.isFinite(reading.chuvaMm)) byDay.set(toDay(reading.data), reading.chuvaMm);
  }
  for (const day of forecastDays) {
    if (Number.isFinite(day.precipitation)) byDay.set(toDay(day.date), day.precipitation);
  }
  return [...byDay.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([date, chuvaMm]) => ({ date, chuvaMm }));
}

// Maior sequência de dias secos que chega até hoje ou depois. Sequências que
// terminaram no passado não contam: a chuva já voltou. Um dia sem dado quebra
// a sequência, para não inventar seca onde falta informação.
export function longestDryRun(timeline, today, relevantRainMm = DEFAULT_RELEVANT_RAIN_MM) {
  let best = null;
  let current = null;

  const close = () => {
    if (current && current.fim >= today && (!best || current.dias > best.dias)) best = current;
    current = null;
  };

  for (const { date, chuvaMm } of timeline) {
    if (current && date !== nextDay(current.fim)) close();
    if (chuvaMm < relevantRainMm) {
      current = current ? { ...current, fim: date, dias: current.dias + 1 } : { inicio: date, fim: date, dias: 1 };
    } else {
      close();
    }
  }
  close();
  return best;
}

// Retorna null quando não há seca, ou { nivel, dias, inicio, fim, data }, em que
// data é o dia em que a sequência passa do limite médio. Essa data não muda
// enquanto a seca continua, então o alerta é atualizado em vez de duplicado.
export function detectProlongedDrought({ history, forecastDays, rule, today }) {
  const limits = rule?.seca_dias_sem_chuva;
  // Limite 0 (ou ausente) desliga a regra, como em chuva_min_mm_semana.
  if (!limits || !(limits.medio > 0)) return null;

  const relevantRainMm = rule.chuva_relevante_mm ?? DEFAULT_RELEVANT_RAIN_MM;
  const timeline = buildRainTimeline(history, forecastDays);
  const referenceDay = today ?? forecastDays?.[0]?.date ?? new Date().toISOString().slice(0, 10);
  const run = longestDryRun(timeline, toDay(referenceDay), relevantRainMm);
  if (!run || run.dias < limits.medio) return null;

  const nivel = limits.alto > 0 && run.dias >= limits.alto ? 'alto' : 'medio';
  return { nivel, ...run, data: addDays(run.inicio, limits.medio - 1) };
}
