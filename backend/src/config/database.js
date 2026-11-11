// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Conecta ao MongoDB e cria índices para as coleções da API.

import { MongoClient } from 'mongodb';
import { env } from './env.js';

const client = new MongoClient(env.mongoUri);

export async function connectDatabase() {
  await client.connect();
  const database = client.db(env.mongoDatabase);

  // Impede contas duplicadas e acelera consultas recorrentes da API.
  await Promise.all([
    database.collection('usuarios').createIndex(
      { email: 1 },
      { unique: true, sparse: true, name: 'email_unico' },
    ),
    database.collection('usuarios').createIndex(
      { telefone: 1 },
      { unique: true, sparse: true, name: 'telefone_unico' },
    ),
    database.collection('propriedades').createIndex(
      { usuarioId: 1 },
      { name: 'propriedades_por_usuario' },
    ),
    database.collection('alertas').createIndex(
      { propriedadeId: 1, tipo: 1, previstoPara: -1 },
      { unique: true, name: 'alertas_sem_duplicados' },
    ),
    database.collection('climaCache').createIndex(
      { atualizadoEm: 1 },
      { expireAfterSeconds: 3 * 60 * 60, name: 'clima_expira_3h' },
    ),
    // Uma leitura por dia por propriedade, apagada após 30 dias (#11).
    database.collection('leituras_clima').createIndex(
      { propriedadeId: 1, data: -1 },
      { unique: true, name: 'leituras_por_propriedade_dia' },
    ),
    database.collection('leituras_clima').createIndex(
      { data: 1 },
      { expireAfterSeconds: 30 * 24 * 60 * 60, name: 'leituras_expira_30d' },
    ),
  ]);

  return database;
}

export async function closeDatabase() {
  await client.close();
}
