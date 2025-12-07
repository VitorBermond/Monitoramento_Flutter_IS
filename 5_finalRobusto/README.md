# Aplicação de monitoramento de métricas de desempenho com modos tempo real e histórico

Esse projeto é uma interface flutter que recebe valores simulados de multiplas métricas via RabbitMQ e as plota em gráfico construídos usando a biblioteca fl_charts. A aplicação também conta com serviços de simulação localizados na pasta /python_services. Esses serviços foram utilizados para validação e escrita do TCC do projeto.

# ⚙️ Pré-requisitos

RabbitMQ rodando (Se não estiver rodando na máquina local, o ip das conexões poderá ser alterado dentro da aplicação)

docker run -it --rm --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:4-management

Flutter instalado

Python instalado

Git instalado

# Instruções para executar o projeto

## Clone o repositório

git clone https://github.com/VitorBermond/Monitoramento_Flutter_IS.git

## Entre na pasta referente a este projeto

cd Monitoramento_Flutter_IS/3_final

## Inicie os serviços de publicação e de tratamento de históricos desejados

cd python_services

(por exemplo, para monitorar CPU)

python3 pubunixCPU.py

python3 reqhistunixCPU.py

## Preparação e execução da aplicação Flutter

cd .. (volta para o diretório)

flutter clean 

flutter pub get

flutter run

# Se tudo cer certo...

A aplicação irá abrir. Existirá diferentes telas para serem acessadas e monitorar as respectivas métricas. Mais informações no documento do TCC.
