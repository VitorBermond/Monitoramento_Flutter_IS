# Aplicação de monitoramento de métricas de desempenho com modos tempo real e histórico

Esse projeto é uma interface flutter que recebe valores simulados de multiplas métricas via RabbitMQ e as plota em gráfico construídos usando a biblioteca fl_charts.

# ⚙️ Pré-requisitos

Sistema operacional Linux

RabbitMQ rodando (Se não estiver rodando na máquina local, o ip das conexões poderá ser alterado dentro da aplicação)

docker run -it --rm --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:4-management

# Instruções para executar o projeto

Abra o executável (monitoramentoapp)

# Se tudo cer certo...

A aplicação irá abrir. Existirá diferentes telas para serem acessadas e monitorar as respectivas métricas. Mais informações no documento do TCC.
