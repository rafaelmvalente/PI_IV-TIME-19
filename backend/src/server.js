// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Inicializa a conexão MongoDB e inicia o servidor HTTP da API.

import { createApp } from './app.js';
import { closeDatabase, connectDatabase } from './config/database.js';
import { env } from './config/env.js';

const database = await connectDatabase();
const server = createApp(database).listen(env.port, () => {
  console.log(`ClimAlerta API disponível na porta ${env.port}.`);
});

async function shutdown(signal) {
  console.log(`Recebido ${signal}; encerrando servidor...`);
  // Fecha as conexões após concluir as requisições em andamento.
  server.close(async (error) => {
    if (error) {
      console.error('Erro ao encerrar o servidor:', error);
      process.exitCode = 1;
    }
    await closeDatabase();
    process.exit();
  });
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
