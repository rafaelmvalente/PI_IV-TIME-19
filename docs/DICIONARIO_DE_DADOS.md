# Dicionário de Dados – ClimAlerta

Banco: **MongoDB** (`climalerta`), hospedado no MongoDB Atlas.
Scripts de criação em `banco-de-dados/`, na ordem: `validadores.js` → `indices.js` → `risco_cultura.js`.

## Visão geral

| Coleção | Descrição | Relacionamento |
|---|---|---|
| `usuarios` | Contas dos produtores | 1 usuário → N propriedades |
| `propriedades` | Propriedades rurais cadastradas | N → 1 `usuarios`; 1 → N `alertas`, `leituras_clima`; 1 → 1 `climaCache` |
| `alertas` | Alertas de risco climático gerados para cada propriedade | N → 1 `propriedades` |
| `climaCache` | Última previsão do tempo de cada propriedade (cache de 3 h) | 1 → 1 `propriedades` |
| `leituras_clima` | Histórico diário de chuva e temperatura (30 dias) | N → 1 `propriedades` |
| `risco_cultura` | Limites climáticos de risco por cultura e estágio | Consultada por `cultivo` + `estagio` da propriedade |

Convenções: datas são `Date` (UTC); `ObjectId` é o identificador gerado pelo MongoDB; "Obrig." indica se o campo é obrigatório no validador.

---

## 1. `usuarios`

| Campo | Tipo | Obrig. | Descrição | Restrições |
|---|---|---|---|---|
| `_id` | ObjectId | Sim | Identificador do usuário | Gerado pelo MongoDB |
| `nome` | String | Sim | Nome do produtor | 2 a 100 caracteres |
| `email` | String | Não* | E-mail de login | Formato de e-mail; único (índice `email_unico`, sparse); salvo em minúsculas |
| `telefone` | String | Não* | Telefone de login e de envio de SMS | 8 a 20 caracteres, com DDD; validado pelo servidor Java; único (índice `telefone_unico`, sparse) |
| `senhaHash` | String | Sim | Hash da senha | bcrypt (custo 12); a senha nunca é salva em texto |
| `preferencias` | Object | Sim | Canais de alerta escolhidos | Ver subcampos |
| `preferencias.texto` | Boolean | Sim | Recebe alerta em texto no app | Padrão `true` |
| `preferencias.voz` | Boolean | Sim | Recebe alerta em áudio no app | Padrão `false` |
| `preferencias.sms` | Boolean | Sim | Recebe SMS nos alertas críticos | Padrão `false` |
| `resetTokenHash` | String | Não | Hash SHA-256 do token de recuperação de senha | Removido após a troca da senha |
| `resetTokenExpiresAt` | Date | Não | Validade do token de recuperação | 15 minutos após o pedido |
| `criadoEm` | Date | Sim | Data de cadastro | |
| `atualizadoEm` | Date | Não | Data da última alteração | |

\* A conta precisa ter **e-mail ou telefone** (pelo menos um); quem garante isso é o backend.

## 2. `propriedades`

| Campo | Tipo | Obrig. | Descrição | Restrições |
|---|---|---|---|---|
| `_id` | ObjectId | Sim | Identificador da propriedade | |
| `usuarioId` | ObjectId | Sim | Dono da propriedade | Referência a `usuarios._id`; índice `propriedades_por_usuario` |
| `nome` | String | Sim | Nome da propriedade | 2 a 100 caracteres |
| `cultivo` | String | Sim | Cultura plantada | `milho`, `feijao`, `soja`, `cafe`, `hortalicas`, `frutas`, `outro`; índice `propriedades_por_cultivo` |
| `estagio` | String | Não | Estágio da lavoura | `plantio`, `crescimento`, `floracao`, `colheita`; se ausente, as regras usam `crescimento` |
| `localizacao` | Object | Sim | Coordenadas da propriedade | |
| `localizacao.latitude` | Number | Sim | Latitude | -90 a 90 |
| `localizacao.longitude` | Number | Sim | Longitude | -180 a 180 |
| `areaHectares` | Number | Não | Área em hectares | Maior que 0 e até 1.000.000 |
| `criadoEm` | Date | Sim | Data de cadastro | |
| `atualizadoEm` | Date | Não | Data da última alteração | |

## 3. `alertas`

| Campo | Tipo | Obrig. | Descrição | Restrições |
|---|---|---|---|---|
| `_id` | ObjectId | Sim | Identificador do alerta | |
| `propriedadeId` | ObjectId | Sim | Propriedade afetada | Referência a `propriedades._id` |
| `tipo` | String | Sim | Tipo de risco | `geada`, `seca`, `chuvaForte` |
| `nivel` | String | Sim | Gravidade | `medio`, `alto` (o SMS só sai para `alto`) |
| `previstoPara` | Date | Sim | Dia previsto do evento | Gravado às 12:00 UTC do dia |
| `descricao` | String | Sim | Texto do alerta mostrado ao produtor | Não vazio |
| `status` | String | Sim | Situação definida pelo produtor | `emAndamento` (padrão), `acaoRealizada`, `resolvido` |
| `recomendacao` | Object | Sim | O que fazer diante do risco | |
| `recomendacao.acao` | String | Sim | Ação principal recomendada | Não vazio |
| `recomendacao.detalhe` | String | Não | Explicação da ação | |
| `recomendacao.dicas` | Array\<String\> | Não | Dicas extras | |
| `notificadoEm` | Date / null | Não | Controle de notificação | `null` ao criar e ao subir de nível |
| `notificacoes.sms` | Object | Não | Situação do envio do SMS | Ver subcampos |
| `notificacoes.sms.status` | String | — | Etapa do envio | `enviando`, `enviado`, `falhou` |
| `notificacoes.sms.em` | Date | — | Momento da etapa | |
| `notificacoes.sms.sid` | String | Não | ID da mensagem no provedor de SMS | Só quando `enviado` |
| `notificacoes.sms.erro` | String | Não | Mensagem de erro | Só quando `falhou` |
| `criadoEm` | Date | Sim | Data em que o alerta foi gerado | |
| `atualizadoEm` | Date | Não | Última vez que o alerta foi gerado de novo ou alterado | |

Índices: `alertas_por_propriedade_data` (`propriedadeId`, `previstoPara`), `alertas_por_status` (`propriedadeId`, `status`) e `alertas_sem_duplicados` (**único** em `propriedadeId` + `tipo` + `previstoPara`: um alerta por tipo e dia em cada propriedade).

## 4. `climaCache`

| Campo | Tipo | Obrig. | Descrição | Restrições |
|---|---|---|---|---|
| `_id` | ObjectId | Sim | Igual ao `_id` da propriedade | Um documento por propriedade |
| `propriedadeId` | ObjectId | Sim | Propriedade da previsão | Referência a `propriedades._id` |
| `forecast` | Object | Sim | Previsão vinda do Open-Meteo | |
| `forecast.fetchedAt` | Date | — | Momento da consulta à API | |
| `forecast.current.temperatura` | Number | Sim | Temperatura atual (°C) | |
| `forecast.current.descricao` | String | Sim | Condição do tempo em texto | |
| `forecast.daily[]` | Array\<Object\> | Sim | Previsão dia a dia | |
| `forecast.daily[].date` | String | — | Dia (`AAAA-MM-DD`) | |
| `forecast.daily[].maxima` | Number | — | Temperatura máxima (°C) | |
| `forecast.daily[].minima` | Number | — | Temperatura mínima (°C) | |
| `forecast.daily[].precipitation` | Number | — | Chuva prevista (mm) | |
| `atualizadoEm` | Date | Sim | Data em que o cache foi gravado | **TTL: apagado após 3 horas** (`clima_expira_3h`) |

## 5. `leituras_clima`

| Campo | Tipo | Obrig. | Descrição | Restrições |
|---|---|---|---|---|
| `_id` | ObjectId | Sim | Identificador da leitura | |
| `propriedadeId` | ObjectId | Sim | Propriedade da leitura | Referência a `propriedades._id` |
| `data` | Date | Sim | Dia da leitura | Única por propriedade e dia (`leituras_por_propriedade_dia`); **TTL: apagada após 30 dias** (`leituras_expira_30d`) |
| `chuvaMm` | Number | Sim | Chuva registrada no dia (mm) | Usada para contar os dias seguidos sem chuva (seca prolongada) |
| `tempMin` | Number | Não | Temperatura mínima do dia (°C) | |
| `tempMax` | Number | Não | Temperatura máxima do dia (°C) | |
| `fonte` | String | Sim | Origem do dado | `open-meteo` |
| `atualizadoEm` | Date | Sim | Data da gravação | |

## 6. `risco_cultura`

Tabela fixa com **28 documentos** (7 culturas × 4 estágios), carregada por `risco_cultura.js`. Os limites vêm em pares `{ medio, alto }`: passou do primeiro valor o alerta é Médio; passou do segundo, Alto.

| Campo | Tipo | Descrição | Regra |
|---|---|---|---|
| `_id` | String | Chave `cultura_estagio` (ex.: `soja_plantio`) | |
| `cultura` | String | Cultura | Mesmos valores de `propriedades.cultivo` |
| `estagio` | String | Estágio da lavoura | Mesmos valores de `propriedades.estagio` |
| `temp_min_c` | Object `{medio, alto}` | Geada | Temperatura mínima ≤ limite |
| `temp_max_c` | Object `{medio, alto}` | Calor | Temperatura máxima ≥ limite |
| `chuva_min_mm_semana` | Object `{medio, alto}` | Seca na semana | Chuva da semana ≤ limite (0 = sem alerta) |
| `chuva_max_mm_semana` | Object `{medio, alto}` | Chuva forte na semana | Chuva da semana ≥ limite |
| `chuva_max_mm_dia` | Object `{medio, alto}` | Chuva forte em 24 h | Chuva do dia ≥ limite |
| `seca_dias_sem_chuva` | Object `{medio, alto}` | Seca prolongada | Dias seguidos sem chuva relevante ≥ limite (0 = sem alerta) |
| `chuva_relevante_mm` | Number | Chuva mínima para o dia não contar como seco | Valor atual: 2 mm |

Índice: `risco_por_cultura_estagio` (**único** em `cultura` + `estagio`).