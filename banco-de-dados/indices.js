// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Cria e valida índices usados pelas consultas do banco ClimAlerta.

function criarIndice(colecao, chaves, opcoes) {
  const c = db.getCollection(colecao);
  let indices = [];
  try {
    indices = c.getIndexes();
  } catch (error) {
    print("[aviso] Não foi possível listar os índices de " + colecao + ": " + error.message);
  }
  const existente = indices.find((i) => JSON.stringify(i.key) === JSON.stringify(chaves));
  if (!existente) {
    c.createIndex(chaves, opcoes);
    print("[criado]   " + colecao + ": " + opcoes.name);
    return;
  }
  print("[já existe] " + colecao + ": " + existente.name);

  // Atualiza a expiração do índice TTL quando o valor cadastrado é diferente.
  if (opcoes.expireAfterSeconds !== undefined && existente.expireAfterSeconds !== opcoes.expireAfterSeconds) {
    db.runCommand({ collMod: colecao, index: { keyPattern: chaves, expireAfterSeconds: opcoes.expireAfterSeconds } });
    print("            TTL ajustado para " + opcoes.expireAfterSeconds + " segundos");
  }
  if (opcoes.unique && !existente.unique) {
    print("            ATENÇÃO: o índice existente não está configurado como único.");
  }
  if (opcoes.sparse && !existente.sparse) {
    print("            ATENÇÃO: o índice existente não está configurado como sparse.");
  }
}

// Acelera consultas dos alertas por propriedade e data.
criarIndice("alertas", { propriedadeId: 1, previstoPara: -1 }, { name: "alertas_por_propriedade_data" });

// Filtra alertas por tipo e evita duplicatas da mesma propriedade e data.
criarIndice("alertas", { propriedadeId: 1, tipo: 1, previstoPara: -1 }, { name: "alertas_sem_duplicados", unique: true });

// Acelera consultas de alertas por propriedade e status.
criarIndice("alertas", { propriedadeId: 1, status: 1 }, { name: "alertas_por_status" });

// Acelera consultas do cache climático por propriedade e data.
criarIndice("climaCache", { propriedadeId: 1, atualizadoEm: -1 }, { name: "clima_por_propriedade_data" });

// Define expiração automática do cache climático após três horas.
criarIndice("climaCache", { atualizadoEm: 1 }, { name: "clima_expira_3h", expireAfterSeconds: 3 * 60 * 60 });

// Impede duplicatas e mantém login único por e-mail ou telefone.
criarIndice("usuarios", { email: 1 }, { name: "email_unico", unique: true, sparse: true });
criarIndice("usuarios", { telefone: 1 }, { name: "telefone_unico", unique: true, sparse: true });

// Acelera consultas de propriedades do usuário.
criarIndice("propriedades", { usuarioId: 1 }, { name: "propriedades_por_usuario" });

// Acelera filtros de propriedades por cultivo.
criarIndice("propriedades", { cultivo: 1 }, { name: "propriedades_por_cultivo" });

// Mantém uma regra de risco por cultura e estágio da lavoura.
criarIndice("risco_cultura", { cultura: 1, estagio: 1 }, { name: "risco_por_cultura_estagio", unique: true });

// Uma leitura de clima por dia por propriedade, usada na seca prolongada (#11).
criarIndice("leituras_clima", { propriedadeId: 1, data: -1 }, { name: "leituras_por_propriedade_dia", unique: true });

// Define expiração automática das leituras de clima após 30 dias.
criarIndice("leituras_clima", { data: 1 }, { name: "leituras_expira_30d", expireAfterSeconds: 30 * 24 * 60 * 60 });
