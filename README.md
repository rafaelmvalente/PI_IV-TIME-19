ClimAlerta

Alertas climáticos hiperlocais para pequenos produtores rurais, por notificação, voz e SMS.

Projeto Integrador IV · Engenharia de Software · PUC-Campinas · Entrega final: 26/11/2026

# Resumo do projeto

Pequenos produtores rurais perdem parte da safra por eventos climáticos (geada, seca prolongada e chuva forte) que poderiam ser evitados com aviso antecipado. As previsões comuns são genéricas, cheias de jargão e dependem de internet.

O ClimAlerta cruza dados meteorológicos públicos (INMET / OpenWeather) com a localização da propriedade, a cultura plantada e o estágio da lavoura. Em vez de só informar a temperatura, avisa o risco real e o que fazer:

Risco de geada (alto) · amanhã, 06:00 Cubra as plantas mais sensíveis com lonas ou plástico agrícola.

# O que precisa ser desenvolvido

Servidor (Java + MongoDB)

Coletar a previsão do tempo automaticamente para cada propriedade
Motor de alertas: comparar o clima com os limites de risco de cada cultura e estágio
Gerar o alerta com a recomendação prática
Autenticação (cadastro e login) e APIs REST de propriedades, alertas e histórico
Enviar o alerta por push (FCM) e por SMS (Twilio) quando o produtor estiver sem internet
Gerar o áudio do alerta (voz)

App mobile (Flutter), 10 telas

Splash, login e cadastro da propriedade (com GPS)
Dashboard com o clima de hoje e os próximos alertas
Lista de alertas com filtros (Todos, Geada, Seca, Chuva) e detalhe com recomendação
Histórico de alertas com status (Em andamento, Ação realizada, Resolvido)
Perfil e configurações (canais de alerta e modo offline/SMS)
Tela de modo offline

Banco de dados (MongoDB)

Coleções: usuarios, propriedades, leituras_clima e alertas
Índice geoespacial (2dsphere) para a localização das propriedades
Índices de performance e carga inicial de culturas e limites de risco

Testes (JUnit)

Motor de alertas, serviços, repositórios e endpoints REST
Tecnologias
Parte	Tecnologia
Servidor	Java 21 + Spring Boot
Banco de dados	MongoDB
App	Flutter
Testes	JUnit 5 + Mockito
Clima	INMET / OpenWeather
Push	Firebase Cloud Messaging
SMS	Twilio

# Integrantes
Nome	RA
Caio Ávila Marchi	25008101
Caique Vasconcelos Naimi	25004208
Rafael Mendes Valente	25002875
Rodrigo Gabi	25001714
Vinicius Santuci Virgolino	25000294
