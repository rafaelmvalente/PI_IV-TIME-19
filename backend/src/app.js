// Nome: Rafael Mendes Valente - RA: 25002875
// Dia: 11/11/2026
// Descrição: Configura as rotas, middlewares e tratamento de erros da API ClimAlerta.

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { env } from './config/env.js';
import authRoutes from './routes/auth.js';
import propertyRoutes from './routes/properties.js';
import alertRoutes from './routes/alerts.js';
import { errorHandler, notFound } from './middleware/errors.js';

export function createApp(database) {
  const app = express();
  app.disable('x-powered-by');
  app.use(helmet());
  app.use(cors({ origin: env.corsOrigin === '*' ? '*' : env.corsOrigin.split(',').map((origin) => origin.trim()) }));
  app.use(express.json({ limit: '32kb' }));
  // Disponibiliza a conexão do banco para os handlers das rotas.
  app.use((req, _res, next) => {
    req.db = database;
    next();
  });

  app.get('/api/v1/health', (_req, res) => res.json({ status: 'ok' }));
  app.use('/api/v1/auth', authRoutes);
  app.use('/api/v1/properties', propertyRoutes);
  app.use('/api/v1/alerts', alertRoutes);
  app.use(notFound);
  app.use(errorHandler);

  return app;
}
