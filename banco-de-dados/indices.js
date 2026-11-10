// Índices do banco climalerta (issue #6).
// Cole no mongosh (ou na aba MongoSH do Compass). Pode colar de novo:
// índice que já existe (com qualquer nome) é pulado.

function criarIndice(colecao, chaves, opcoes) {
  const c = db.getCollection(colecao);
  let indices = [];
  try { indices = c.getIndexes(); } catch (e) { /* coleção ainda não existe */ }
  const existente = indices.find((i) => JSON.stringify(i.key) === JSON.stringify(chaves));
  if (!existente) {
    c.createIndex(chaves, opcoes);
    print("[criado]   " + colecao + ": " + opcoes.name);
    return;
  }
  print("[já existe] " + colecao + ": " + existente.name);

  // O índice existe, mas pode ter sido criado sem a opção que precisamos.
  if (opcoes.expireAfterSeconds !== undefined && existente.expireAfterSeconds !== opcoes.expireAfterSeconds) {
    db.runCommand({ collMod: colecao, index: { keyPattern: chaves, expireAfterSeconds: opcoes.expireAfterSeconds } });
    print("            TTL ajustado para " + opcoes.expireAfterSeconds + " segundos");
  }
  if (opcoes.unique && !existente.unique) {
    print("            ATENÇÃO: este índice não é único. Para deixar único, apague-o com");
    print('            db.' + colecao + '.dropIndex("' + existente.name + '") e cole o script de novo.');
  }
}

// alertas: histórico e dashboard buscam os alertas da propriedade do usuário,
// do mais recente para o mais antigo.
criarIndice("alertas", { propriedadeId: 1, previstoPara: -1 }, { name: "alertas_por_propriedade_data" });

// alertas: filtro por tipo (Geada, Seca, Chuva) no histórico. Por ser único,
// também impede alerta duplicado (mesmo tipo para a mesma data na mesma
// propriedade), como pede o README.
criarIndice("alertas", { propriedadeId: 1, tipo: 1, previstoPara: -1 }, { name: "alertas_sem_duplicados", unique: true });

// alertas: alertas ativos da propriedade (status "emAndamento").
criarIndice("alertas", { propriedadeId: 1, status: 1 }, { name: "alertas_por_status" });

// climaCache: leitura mais recente do clima da propriedade.
criarIndice("climaCache", { propriedadeId: 1, atualizadoEm: -1 }, { name: "clima_por_propriedade_data" });

// climaCache: TTL. O MongoDB apaga sozinho as leituras com mais de 3 horas.
criarIndice("climaCache", { atualizadoEm: 1 }, { name: "clima_expira_3h", expireAfterSeconds: 3 * 60 * 60 });

// usuarios: login pelo e-mail, sem e-mail repetido.
criarIndice("usuarios", { email: 1 }, { name: "email_unico", unique: true });

// propriedades: propriedades do usuário logado.
criarIndice("propriedades", { usuarioId: 1 }, { name: "propriedades_por_usuario" });

// propriedades: listar com filtro por tipo de cultivo (issue #14).
criarIndice("propriedades", { cultivo: 1 }, { name: "propriedades_por_cultivo" });

// risco_cultura: busca pela cultura e estágio da propriedade, sem repetir.
criarIndice("risco_cultura", { cultura: 1, estagio: 1 }, { name: "risco_por_cultura_estagio", unique: true });



