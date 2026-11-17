// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 17/11/2026
// Descrição: Cria as regras de validação (validators) das coleções do banco
// ClimAlerta, iguais ao que o backend grava (issue #80). Pode rodar mais de uma
// vez: se a coleção já existe, atualiza a regra; se não existe, cria a coleção.
//
// Rodar antes de indices.js e risco_cultura.js, no mongosh (colando o script
// inteiro ou com load("validadores.js")). Precisa de um usuário com permissão
// de administrador do banco: o usuário do backend (climalerta_app) não tem.

db = db.getSiblingDB("climalerta"); // "use climalerta" não funciona ao colar o script inteiro

function aplicarValidador(colecao, schema) {
  const validator = { $jsonSchema: schema };
  const existe = db.getCollectionNames().includes(colecao);
  if (existe) {
    db.runCommand({ collMod: colecao, validator, validationLevel: "strict", validationAction: "error" });
    print("[atualizado] " + colecao);
  } else {
    db.createCollection(colecao, { validator, validationLevel: "strict", validationAction: "error" });
    print("[criado]     " + colecao);
  }
}

// Conta com e-mail OU telefone: o backend garante que vem pelo menos um,
// por isso nenhum dos dois é obrigatório aqui.
aplicarValidador("usuarios", {
  bsonType: "object",
  required: ["nome", "senhaHash", "preferencias", "criadoEm"],
  properties: {
    nome: { bsonType: "string", minLength: 1 },
    email: { bsonType: "string", pattern: "^.+@.+\\..+$" },
    telefone: { bsonType: "string" },
    senhaHash: { bsonType: "string" },
    preferencias: { bsonType: "object", required: ["texto", "voz", "sms"] },
    criadoEm: { bsonType: "date" },
  },
});

// A localização é guardada como { latitude, longitude }, como o app envia.
aplicarValidador("propriedades", {
  bsonType: "object",
  required: ["usuarioId", "nome", "cultivo", "localizacao", "criadoEm"],
  properties: {
    localizacao: {
      bsonType: "object",
      required: ["latitude", "longitude"],
      properties: {
        latitude: { bsonType: "number", minimum: -90, maximum: 90 },
        longitude: { bsonType: "number", minimum: -180, maximum: 180 },
      },
    },
  },
});

// Mesmos tipos, níveis e status usados pelas regras de risco e pelo app.
aplicarValidador("alertas", {
  bsonType: "object",
  required: ["propriedadeId", "tipo", "nivel", "previstoPara", "descricao", "status", "recomendacao", "criadoEm"],
  properties: {
    propriedadeId: { bsonType: "objectId" },
    tipo: { enum: ["geada", "seca", "chuvaForte"] },
    nivel: { enum: ["medio", "alto"] },
    previstoPara: { bsonType: "date" },
    descricao: { bsonType: "string", minLength: 1 },
    status: { enum: ["emAndamento", "acaoRealizada", "resolvido"] },
    recomendacao: {
      bsonType: "object",
      required: ["acao"],
      properties: {
        acao: { bsonType: "string", minLength: 1 },
        detalhe: { bsonType: "string" },
        dicas: { bsonType: "array", items: { bsonType: "string" } },
      },
    },
    criadoEm: { bsonType: "date" },
  },
});

// O backend guarda a previsão inteira do Open-Meteo dentro de "forecast".
aplicarValidador("climaCache", {
  bsonType: "object",
  required: ["propriedadeId", "forecast", "atualizadoEm"],
  properties: {
    propriedadeId: { bsonType: "objectId" },
    forecast: { bsonType: "object", required: ["current", "daily"] },
    atualizadoEm: { bsonType: "date" },
  },
});
