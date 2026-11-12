// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Valida tokens JWT e identifica o usuário autenticado.

import jwt from 'jsonwebtoken';
import { ObjectId } from 'mongodb';
import { env } from '../config/env.js';

export function authenticate(req, res, next) {
  const authorization = req.get('authorization');
  const token = authorization?.startsWith('Bearer ')
    ? authorization.slice('Bearer '.length)
    : undefined;

  if (!token) {
    return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Faça login para continuar.' } });
  }

  try {
    // O identificador do token é validado antes de ser usado em consultas MongoDB.
    const payload = jwt.verify(token, env.jwtSecret);
    if (typeof payload !== 'object' || typeof payload.sub !== 'string' || !ObjectId.isValid(payload.sub)) {
      return res.status(401).json({ error: { code: 'INVALID_TOKEN', message: 'Token inválido.' } });
    }

    req.userId = new ObjectId(payload.sub);
    return next();
  } catch {
    return res.status(401).json({ error: { code: 'INVALID_TOKEN', message: 'Token inválido ou expirado.' } });
  }
}
