// Nome: Rafael Mendes Valente - RA: 25002875
// Dia: 11/11/2026
// Descrição: Carrega e valida as configurações de ambiente do backend.

import 'dotenv/config';

const jwtSecret = process.env.JWT_SECRET;
// Garante tamanho mínimo para o segredo de assinatura dos tokens.
if (!jwtSecret || jwtSecret.length < 32) {
  throw new Error('JWT_SECRET precisa ter pelo menos 32 caracteres.');
}

export const env = {
  port: Number(process.env.PORT ?? 3000),
  mongoUri: process.env.MONGODB_URI ?? 'mongodb://127.0.0.1:27017',
  mongoDatabase: process.env.MONGODB_DATABASE ?? 'climalerta',
  jwtSecret,
  corsOrigin: process.env.CORS_ORIGIN ?? '*',
  weatherApiUrl:
    process.env.WEATHER_API_URL ?? 'https://api.open-meteo.com/v1/forecast',
  smtp: {
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT ?? 587),
    secure: process.env.SMTP_SECURE === 'true',
    user: process.env.SMTP_USER,
    password: process.env.SMTP_PASSWORD,
    from: process.env.SMTP_FROM,
  },
  resetPasswordUrl: process.env.APP_RESET_PASSWORD_URL,
};
