// Nome: Rodrigo Gabi - RA: 25001714
// Data: 11/11/2026
// Descrição: Envia SMS pela API REST do Twilio (issue #16).

import { env } from '../config/env.js';

export function smsConfigured(config = env.twilio) {
  return Boolean(config?.accountSid && config?.authToken && config?.from);
}

// O Twilio exige o formato E.164 (+5519987654321). Número sem DDI é tratado
// como brasileiro. Retorna null quando não dá para montar um número válido.
export function toE164(telefone) {
  if (!telefone) return null;
  const digits = String(telefone).replace(/\D/g, '');
  if (String(telefone).trim().startsWith('+')) {
    return digits.length >= 10 && digits.length <= 15 ? `+${digits}` : null;
  }
  if ((digits.length === 12 || digits.length === 13) && digits.startsWith('55')) return `+${digits}`;
  if (digits.length === 10 || digits.length === 11) return `+55${digits}`;
  return null;
}

export async function sendSms(to, body, { config = env.twilio, fetchFn = fetch } = {}) {
  if (!smsConfigured(config)) {
    throw Object.assign(new Error('O envio de SMS não está configurado.'), {
      status: 503,
      code: 'SMS_NOT_CONFIGURED',
    });
  }

  const form = new URLSearchParams({ To: to, Body: body });
  form.set(config.from.startsWith('MG') ? 'MessagingServiceSid' : 'From', config.from);

  const url = `https://api.twilio.com/2010-04-01/Accounts/${encodeURIComponent(config.accountSid)}/Messages.json`;
  const credentials = Buffer.from(`${config.accountSid}:${config.authToken}`).toString('base64');

  let response;
  try {
    response = await fetchFn(url, {
      method: 'POST',
      headers: {
        authorization: `Basic ${credentials}`,
        'content-type': 'application/x-www-form-urlencoded',
      },
      body: form,
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    throw Object.assign(new Error('O serviço de SMS está indisponível.'), {
      status: 502,
      code: 'SMS_PROVIDER_UNAVAILABLE',
    });
  }

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw Object.assign(new Error(data.message ?? 'O Twilio recusou o envio do SMS.'), {
      status: 502,
      code: 'SMS_PROVIDER_ERROR',
    });
  }
  return { sid: data.sid };
}
