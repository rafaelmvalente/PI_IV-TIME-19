// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Padroniza respostas para erros de validação, requisição e servidor.

import { ZodError } from 'zod';

export function notFound(req, res) {
  return res.status(404).json({
    error: { code: 'NOT_FOUND', message: `Rota não encontrada: ${req.method} ${req.path}` },
  });
}

export function errorHandler(error, req, res, _next) {
  if (error?.type === 'entity.parse.failed') {
    return res.status(400).json({
      error: { code: 'INVALID_JSON', message: 'O corpo da requisição não contém JSON válido.' },
    });
  }
  if (error?.type === 'entity.too.large') {
    return res.status(413).json({
      error: { code: 'PAYLOAD_TOO_LARGE', message: 'O corpo da requisição excede o limite permitido.' },
    });
  }

  if (error instanceof ZodError) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Os dados enviados são inválidos.',
        details: error.issues.map(({ path, message }) => ({ field: path.join('.'), message })),
      },
    });
  }

  if (error?.code === 11000) {
    return res.status(409).json({
      error: { code: 'DUPLICATE', message: 'Já existe um registro com esses dados.' },
    });
  }

  if (error?.status && error?.code) {
    return res.status(error.status).json({
      error: { code: error.code, message: error.message },
    });
  }

  console.error(error);
  return res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'Ocorreu um erro interno.' },
  });
}
