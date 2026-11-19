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

// Aplica a regra ($jsonSchema) em uma coleção.
// - validationLevel "strict": a regra vale para TODO insert e update.
// - validationAction "error": o MongoDB RECUSA o documento fora da regra
//   (com "warn" ele só registraria um aviso no log e gravaria assim mesmo).
function aplicarValidador(colecao, schema) {
  const validator = { $jsonSchema: schema };
  const existe = db.getCollectionNames().includes(colecao);
  if (existe) {
    // collMod altera a regra de uma coleção que já existe, sem apagar os dados.
    db.runCommand({ collMod: colecao, validator, validationLevel: "strict", validationAction: "error" });
    print("[atualizado] " + colecao);
  } else {
    // Coleção nova: cria já com a regra.
    db.createCollection(colecao, { validator, validationLevel: "strict", validationAction: "error" });
    print("[criado]     " + colecao);
  }
}

// Conta com e-mail OU telefone: o backend garante que vem pelo menos um,
// por isso nenhum dos dois é obrigatório aqui.
aplicarValidador("usuarios", {
  bsonType: "object",
  // Campos que todo usuário precisa ter.
  required: ["nome", "senhaHash", "preferencias", "criadoEm"],
  properties: {
    nome: { bsonType: "string", minLength: 1 },
    // Formato mínimo de e-mail: algo@algo.algo
    email: { bsonType: "string", pattern: "^.+@.+\\..+$" },
    telefone: { bsonType: "string" },
    // Só o hash (bcrypt) da senha é guardado, nunca a senha em si.
    senhaHash: { bsonType: "string" },
    // Como o produtor quer receber os alertas: texto e/ou voz.
    preferencias: { bsonType: "object", required: ["texto", "voz"] },
    criadoEm: { bsonType: "date" },
  },
});

// A localização é guardada como { latitude, longitude }, como o app envia.
aplicarValidador("propriedades", {
  bsonType: "object",
  // usuarioId liga a propriedade ao dono (coleção usuarios).
  required: ["usuarioId", "nome", "cultivo", "localizacao", "criadoEm"],
  properties: {
    localizacao: {
      bsonType: "object",
      required: ["latitude", "longitude"],
      properties: {
        // Limites reais do globo: latitude de -90 a 90 e longitude de -180 a 180.
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
    // Propriedade a que o alerta pertence (_id da coleção propriedades).
    propriedadeId: { bsonType: "objectId" },
    // enum: só aceita um destes valores exatos.
    tipo: { enum: ["geada", "seca", "chuvaForte"] },
    nivel: { enum: ["medio", "alto"] },
    // Dia previsto para o risco acontecer.
    previstoPara: { bsonType: "date" },
    descricao: { bsonType: "string", minLength: 1 },
    // O que o produtor fez com o alerta (marcado na tela de detalhe).
    status: { enum: ["emAndamento", "acaoRealizada", "resolvido"] },
    // Recomendação prática: a ação é obrigatória; detalhe e dicas, não.
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
    // current = clima de agora; daily = previsão dia a dia.
    forecast: { bsonType: "object", required: ["current", "daily"] },
    // Quando a previsão foi buscada: o backend reaproveita o cache recente.
    atualizadoEm: { bsonType: "date" },
  },
});
