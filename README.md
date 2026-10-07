# ClimAlerta — Alertas Climáticos Hiperlocais para Pequenos Produtores Rurais

## Sobre o projeto

O ClimAlerta é uma aplicação que avisa pequenos produtores rurais sobre riscos climáticos para a sua lavoura antes que eles aconteçam.

O sistema cruza dados meteorológicos públicos (INMET / OpenWeather) com a localização da propriedade, a cultura plantada e o estágio da lavoura, e transforma a previsão do tempo em um alerta simples, acompanhado de uma recomendação prática.

Em vez de apenas informar a temperatura, o sistema avisa o risco real e o que fazer. Exemplo:

> Risco de geada (alto) — amanhã, 06:00. Cubra as plantas mais sensíveis com lonas ou plástico agrícola.

Os alertas chegam por notificação, em texto ou voz e, quando a propriedade está sem internet estável, os alertas críticos chegam por SMS. Cada alerta fica registrado em um histórico, com o status do que foi feito.

## Equipe

| Nome | RA |
|------|----|
| Caio Ávila Marchi | 25008101 |
| Caique Vasconcelos Naimi | 25004208 |
| Rafael Mendes Valente | 25002875 |
| Rodrigo Gabi | 25001714 |
| Vinicius Santuci Virgolino | 25000294 |

## Funcionalidades

### Conta e propriedade

- Cadastro e login do produtor, com recuperação de senha
- Cadastro da propriedade com nome, tipo de cultivo, tamanho da área (opcional) e localização, por GPS automático ou informada manualmente
- Edição dos dados da propriedade e das preferências de recebimento de alertas

### Alertas de risco climático

- Coleta automática da previsão do tempo para a localização de cada propriedade
- Detecção de três tipos de evento: geada, seca prolongada e chuva forte
- Classificação do alerta por nível de risco (Médio, Alto), conforme a cultura e o estágio da lavoura (plantio, crescimento, floração, colheita)
- Prevenção de alertas duplicados, priorizando o mais grave

### Recomendações práticas

- Cada alerta vem com uma ação sugerida e dicas extras (ex.: "proteja as mudas", "adie a irrigação")
- Linguagem simples, sem jargão técnico

### Canais de alerta

- Notificação push no aplicativo
- Texto e voz: o produtor escolhe receber o alerta escrito e/ou em áudio
- Modo offline / SMS: sem internet estável, os alertas críticos chegam por SMS

### Histórico e acompanhamento

- Lista de alertas recebidos, agrupada por mês
- Status de cada alerta: Em andamento, Ação realizada e Resolvido
- Filtro de alertas por tipo: Todos, Geada, Seca e Chuva

### Dashboard

A tela inicial apresenta:

- Clima de hoje da propriedade
- Alerta em destaque
- Próximos alertas previstos

## Status acompanhados

| Status | Descrição |
|--------|-----------|
| Em andamento | Alerta recebido e situação ainda em curso |
| Ação realizada | Produtor executou a ação recomendada |
| Resolvido | Risco encerrado |

## Tecnologias utilizadas

- Aplicativo (cliente): Flutter (Dart)
- Servidor: Java 21, Spring Boot (API REST)
- Banco de dados: MongoDB
- Testes automatizados: JUnit 5, Mockito
- Integrações: INMET / OpenWeather (clima), Firebase Cloud Messaging (push) e Twilio (SMS)
- Controle de versão: Git, GitHub e GitHub Projects
