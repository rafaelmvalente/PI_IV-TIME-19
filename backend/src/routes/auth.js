// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Implementa cadastro, autenticação, perfil e recuperação de senha.

import { Router } from 'express';
import bcrypt from 'bcryptjs';
import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';
import nodemailer from 'nodemailer';
import { z } from 'zod';
import { env } from '../config/env.js';
import { authenticate } from '../middleware/authenticate.js';
import { toE164 } from '../services/sms.js';
import { confirmarTelefone } from '../services/validacaoTelefone.js';

const router = Router();
const passwordSchema = z.string().min(8).max(128);
const emailSchema = z.string().trim().email().transform((value) => value.toLowerCase());

function publicUser(user) {
  // A resposta pública não inclui hash de senha nem dados internos de recuperação.
  return {
    id: String(user._id),
    nome: user.nome,
    email: user.email ?? null,
    telefone: user.telefone ?? null,
    preferencias: user.preferencias,
  };
}

function createToken(userId) {
  // O token expira após sete dias e identifica o usuário pelo subject.
  return jwt.sign({}, env.jwtSecret, { subject: String(userId), expiresIn: '7d' });
}

function smtpConfigured() {
  const { host, user, password, from } = env.smtp;
  return Boolean(host && user && password && from && env.resetPasswordUrl);
}

router.post('/register', async (req, res) => {
  const body = z
    .object({
      nome: z.string().trim().min(2).max(100),
      email: emailSchema.optional(),
      telefone: z.string().trim().min(8).max(20).optional(),
      senha: passwordSchema,
    })
    .refine((value) => value.email || value.telefone, {
      message: 'Informe um e-mail ou telefone.',
      path: ['email'],
    })
    .parse(req.body);
  if (body.telefone) await confirmarTelefone(body.telefone);

  const user = {
    nome: body.nome,
    ...(body.email ? { email: body.email } : {}),
    ...(body.telefone ? { telefone: body.telefone } : {}),
    senhaHash: await bcrypt.hash(body.senha, 12),
    preferencias: { texto: true, voz: false, sms: false },
    criadoEm: new Date(),
  };

  const result = await req.db.collection('usuarios').insertOne(user);
  res.status(201).json({ usuario: publicUser({ ...user, _id: result.insertedId }), token: createToken(result.insertedId) });
});

router.post('/login', async (req, res) => {
  const body = z
    .object({
      login: z.string().trim().min(1),
      senha: z.string().min(1).max(128),
    })
    .parse(req.body);
  const login = body.login.includes('@') ? body.login.toLowerCase() : body.login;
  const user = await req.db.collection('usuarios').findOne({
    $or: [{ email: login }, { telefone: login }],
  });

  if (!user || !(await bcrypt.compare(body.senha, user.senhaHash))) {
    return res.status(401).json({
      error: { code: 'INVALID_CREDENTIALS', message: 'Login ou senha inválidos.' },
    });
  }

  return res.json({ usuario: publicUser(user), token: createToken(user._id) });
});

router.get('/me', authenticate, async (req, res) => {
  const user = await req.db.collection('usuarios').findOne(
    { _id: req.userId },
    { projection: { senhaHash: 0, resetTokenHash: 0, resetTokenExpiresAt: 0 } },
  );
  if (!user) {
    return res.status(404).json({ error: { code: 'USER_NOT_FOUND', message: 'Usuário não encontrado.' } });
  }
  return res.json(publicUser(user));
});

router.patch('/me/preferences', authenticate, async (req, res) => {
  const preferences = z
    .object({
      texto: z.boolean(),
      voz: z.boolean(),
      sms: z.boolean(),
    })
    .refine((value) => value.texto || value.voz || value.sms, {
      message: 'Mantenha pelo menos um canal de recebimento ativo.',
    })
    .parse(req.body);

  const user = await req.db.collection('usuarios').findOneAndUpdate(
    { _id: req.userId },
    { $set: { preferencias: preferences, atualizadoEm: new Date() } },
    { returnDocument: 'after', projection: { senhaHash: 0 } },
  );
  if (!user) {
    return res.status(404).json({ error: { code: 'USER_NOT_FOUND', message: 'Usuário não encontrado.' } });
  }
  return res.json(publicUser(user));
});

// Cadastra ou troca o telefone da conta, usado no SMS dos alertas críticos.
// Quem criou a conta pelo e-mail não tinha como informar o número.
router.patch('/me/telefone', authenticate, async (req, res) => {
  const { telefone } = z
    .object({
      telefone: z.string().trim().min(8).max(20)
        .refine((value) => toE164(value), { message: 'Informe o telefone com DDD.' }),
    })
    .parse(req.body);
  await confirmarTelefone(telefone);

  const user = await req.db.collection('usuarios').findOneAndUpdate(
    { _id: req.userId },
    { $set: { telefone, atualizadoEm: new Date() } },
    { returnDocument: 'after', projection: { senhaHash: 0 } },
  );
  if (!user) {
    return res.status(404).json({ error: { code: 'USER_NOT_FOUND', message: 'Usuário não encontrado.' } });
  }
  return res.json(publicUser(user));
});

router.post('/forgot-password', async (req, res) => {
  if (!smtpConfigured()) {
    return res.status(503).json({
      error: {
        code: 'EMAIL_NOT_CONFIGURED',
        message: 'Recuperação de senha indisponível: configure o envio SMTP no backend.',
      },
    });
  }
  const { login } = z.object({ login: z.string().trim().min(1) }).parse(req.body);
  const normalizedLogin = login.includes('@') ? login.toLowerCase() : login;
  const user = await req.db.collection('usuarios').findOne({
    $or: [{ email: normalizedLogin }, { telefone: normalizedLogin }],
  });
  const genericResponse = { mensagem: 'Se a conta existir, enviaremos as instruções de recuperação.' };

  if (user?.email) {
    const rawToken = crypto.randomBytes(32).toString('hex');
    // Somente o hash do token de recuperação é armazenado no banco.
    const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
    await req.db.collection('usuarios').updateOne(
      { _id: user._id },
      { $set: { resetTokenHash: tokenHash, resetTokenExpiresAt: new Date(Date.now() + 15 * 60_000) } },
    );
    const resetUrl = new URL(env.resetPasswordUrl);
    resetUrl.searchParams.set('token', rawToken);
    const transporter = nodemailer.createTransport({
      host: env.smtp.host,
      port: env.smtp.port,
      secure: env.smtp.secure,
      auth: { user: env.smtp.user, pass: env.smtp.password },
    });
    await transporter.sendMail({
      from: env.smtp.from,
      to: user.email,
      subject: 'Recuperação de senha - ClimAlerta',
      text: `Use este link para redefinir sua senha em até 15 minutos: ${resetUrl}`,
    });
  }

  return res.status(202).json(genericResponse);
});

router.post('/reset-password', async (req, res) => {
  const body = z
    .object({
      token: z.string().min(32),
      novaSenha: passwordSchema,
    })
    .parse(req.body);
  const tokenHash = crypto.createHash('sha256').update(body.token).digest('hex');
  const user = await req.db.collection('usuarios').findOne({
    resetTokenHash: tokenHash,
    resetTokenExpiresAt: { $gt: new Date() },
  });

  if (!user) {
    return res.status(400).json({
      error: { code: 'INVALID_RESET_TOKEN', message: 'Link de recuperação inválido ou expirado.' },
    });
  }

  await req.db.collection('usuarios').updateOne(
    { _id: user._id },
    {
      $set: { senhaHash: await bcrypt.hash(body.novaSenha, 12), atualizadoEm: new Date() },
      $unset: { resetTokenHash: '', resetTokenExpiresAt: '' },
    },
  );
  return res.json({ mensagem: 'Senha alterada com sucesso.' });
});

export default router;
