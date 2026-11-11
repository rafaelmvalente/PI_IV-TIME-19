// Nome: Rodrigo Gabi - RA: 25001714
// Data: 11/11/2026
// Descrição: Roda a coleta de clima e a análise de alertas de todas as propriedades no intervalo definido (issue #8).

import { refreshAlerts } from '../routes/alerts.js';

// Uma propriedade por vez, para não estourar o limite de consultas do
// Open-Meteo. Erro em uma propriedade não interrompe as outras.
export async function runCollectionCycle(database, { refresh = refreshAlerts, logger = console } = {}) {
  const startedAt = Date.now();
  const summary = { total: 0, sucesso: 0, falhas: 0 };
  const cursor = database.collection('propriedades').find({});

  for await (const property of cursor) {
    summary.total += 1;
    try {
      await refresh(database, property);
      summary.sucesso += 1;
    } catch (error) {
      summary.falhas += 1;
      logger.error(`[coleta] Falha na propriedade ${property._id}: ${error.message}`);
    }
  }

  summary.duracaoMs = Date.now() - startedAt;
  logger.log(
    `[coleta] ${summary.sucesso}/${summary.total} propriedades analisadas` +
      (summary.falhas ? `, ${summary.falhas} com falha` : '') +
      ` em ${summary.duracaoMs} ms.`,
  );
  return summary;
}

// Roda um ciclo logo depois de iniciar e depois a cada intervalMinutes.
// Se um ciclo ainda estiver rodando quando o próximo chegar, o próximo é pulado.
export function startCollectionScheduler(database, {
  intervalMinutes,
  initialDelayMs = 5_000,
  runCycle = runCollectionCycle,
  logger = console,
} = {}) {
  if (!(intervalMinutes > 0)) {
    logger.log('[coleta] Agendamento desligado (COLETA_INTERVALO_MINUTOS = 0).');
    return { stop: async () => {} };
  }

  let running = null;
  const tick = () => {
    if (running) {
      logger.warn('[coleta] Ciclo anterior ainda em andamento; este foi pulado.');
      return;
    }
    running = Promise.resolve()
      .then(() => runCycle(database, { logger }))
      .catch((error) => logger.error('[coleta] Erro inesperado no ciclo:', error))
      .finally(() => {
        running = null;
      });
  };

  const firstRun = setTimeout(tick, initialDelayMs);
  const interval = setInterval(tick, intervalMinutes * 60_000);
  logger.log(`[coleta] Agendada a cada ${intervalMinutes} minuto(s).`);

  return {
    tick,
    // Espera o ciclo em andamento terminar antes de fechar o banco.
    async stop() {
      clearTimeout(firstRun);
      clearInterval(interval);
      await running;
    },
  };
}
